//
//  UIControl+CombineAddons.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import Combine
import UIKit


extension UIControl: CombineAddons { }


/// Extending the `UIControl` types to be able to produce a `UIControl.Event` publisher.
protocol CombineAddons {
	func makePublisher(for events: UIControl.Event) -> UIControlPublisher<UIControl>
}


extension CombineAddons where Self: UIControl {
	func makePublisher(for events: UIControl.Event) -> UIControlPublisher<UIControl> {
		UIControlPublisher(control: self, events: events)
	}
}

/// A custom `Publisher` to work with our custom `UIControlSubscription`.
public struct UIControlPublisher<Control: UIControl>: Publisher {
	public typealias Output = Control
	public typealias Failure = Never
	
	let control: Control
	let controlEvents: UIControl.Event
	
	init(
		control: Control,
		events: UIControl.Event
	) {
		self.control = control
		self.controlEvents = events
	}
	
	public func receive<S>(subscriber: S)
	where S: Subscriber,
		  S.Failure == UIControlPublisher.Failure,
		  S.Input == UIControlPublisher.Output {
			  let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
			  subscriber.receive(subscription: subscription)
		  }
}

/// A custom `UIControlSubscription`.
final class UIControlSubscription<SubscriberType: Subscriber, Control: UIControl>: Subscription
where SubscriberType.Input == Control {
	private var subscriber: SubscriberType?
	private let control: Control
	
	init(
		subscriber: SubscriberType,
		control: Control,
		event: UIControl.Event
	) {
		self.subscriber = subscriber
		self.control = control
		control.addTarget(self, action: #selector(eventHandler), for: event)
	}
	
	public func request(_: Subscribers.Demand) {}
	
	public func cancel() {
		subscriber = nil
	}
	
	@objc
	private func eventHandler() {
		_ = subscriber?.receive(control)
	}
}




