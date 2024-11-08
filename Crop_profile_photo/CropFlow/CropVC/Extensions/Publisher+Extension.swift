//
//  Publisher+Extension.swift
//  Crop_profile_photo
//
//  Created by Maxnxi on 11/09/24
//

import Combine

extension Publisher {
	func asyncTryMap<T>(
		_ transform: @escaping (Output) async throws -> T
	) -> Publishers.FlatMap<Future<T, Error>, Self> {
		flatMap { value in
			Future { promise in
				Task {
					do {
						let output = try await transform(value)
						promise(.success(output))
					} catch {
						promise(.failure(error))
					}
				}
			}
		}
	}
}
