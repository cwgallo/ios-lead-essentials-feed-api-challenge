//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url, completion: { [weak self] result in
			guard self != nil else { return }

			switch result {
			case let .success((data, httpResponse)):
				if httpResponse.statusCode == 200,
				   let root = try? JSONDecoder().decode(Root.self, from: data) {
					completion(.success(root.items.map { $0.feedImage }))
				} else {
					completion(.failure(Error.invalidData))
				}
			case .failure:
				completion(.failure(Error.connectivity))
			}
		})
	}

	private struct Root: Decodable {
		let items: [APIFeedImage]
	}

	private struct APIFeedImage: Hashable, Decodable {
		let id: UUID
		let description: String?
		let location: String?
		let url: URL

		enum CodingKeys: String, CodingKey {
			case id = "image_id"
			case description = "image_desc"
			case location = "image_loc"
			case url = "image_url"
		}

		var feedImage: FeedImage {
			FeedImage(id: id,
			          description: description,
			          location: location,
			          url: url)
		}

		init(id: UUID, description: String?, location: String?, url: URL) {
			self.id = id
			self.description = description
			self.location = location
			self.url = url
		}
	}
}
