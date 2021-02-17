//
//  SearchViewController.swift
//  MyNetflix
//
//  Created by joonwon lee on 2020/04/02.
//  Copyright © 2020 com.joonwon. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    
    var movies: [Movie] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension SearchViewController: UICollectionViewDataSource{
    // 몇개 넘어옴?
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCell", for: indexPath) as?  ResultCell else{
            return UICollectionViewCell()
        }
        let movie = movies[indexPath.item]
        //Image Path를 가지고 실제 이미지로 어떻게 만들것인지?
        // Third Party , 외부 코드 가져다 쓰기...라이브러리!
        // SPM(Swift Package Manager), CoCoa Pod, Carthage
        
        //cell.movieThumbnail.image = movie.thumbnailPath
        let url = URL(string: movie.thumbnailPath)!
        cell.movieThumbnail.kf.setImage(with: url)
        cell.backgroundColor = .red
        return cell
    }
}

extension SearchViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = movies[indexPath.item]
        let url = URL(string: movie.previewURL)!
        let item = AVPlayerItem(url: url)
        
        
        let sb = UIStoryboard(name: "Player", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "PlayerViewController") as! PlayerViewController//ViewController
        vc.modalPresentationStyle = .fullScreen
        
        vc.player.replaceCurrentItem(with: item)
        present(vc, animated: false, completion: nil)
        
    }
}

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let margin: CGFloat = 8
        let itemSpacing: CGFloat = 10
        let width = (collectionView.bounds.width - margin * 2 - itemSpacing * 2) / 3
        let height = width * 10/7
        return CGSize(width: width, height: height)
    }
}


class ResultCell: UICollectionViewCell{
    @IBOutlet weak var movieThumbnail: UIImageView!
}

extension SearchViewController: UISearchBarDelegate{
    private func dismissKeyboard(){
        searchBar.resignFirstResponder()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //이때 실제 검색을 시작한 것임..
        
        // 검색 시작
        
        // 키보드 올라와 있을때 -> 내려가게 처리하기
        dismissKeyboard()
        // 검색어가 있는가?
        
        guard let searchTerm = searchBar.text,
              searchTerm.isEmpty == false else{
            return
        }
        
        // [v] 네트워킹을 통한 검색
        // - [v] 목표 : Search Term을 가지고, 네트워킹 통해 영화 검색하기
        SearchAPI.search(searchTerm){movies in
            print("--> 몇개 넘어왔는가? \(movies.count), 첫번째 꺼 제목 :\(movies.first?.title)")
            DispatchQueue.main.async {
                self.movies = movies
                self.resultCollectionView.reloadData()//Main Thread에서 불려야하는데 왜 여기서 불리는지?...
            }
            
            //네트워킹은 느린작업이라 Main Thread에 돌리면 안된다....
        }
        
        // - [v] 결과를 받아올 모델 Movie, Response 모델도 필요함!
        // - 결과를 받아와서, CollectionView로 표현해줘야함
        print("---> 검색어 : \(searchTerm)")
    }
}

class SearchAPI{
    //Type Method
    static func search(_ term: String, completion: @escaping ([Movie]) -> Void){
        //Method 밖에서도 나타낼수있다능..
        let session = URLSession(configuration: .default)
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
        let mediaQuery = URLQueryItem(name: "media", value: "movie")
        let entityQuery = URLQueryItem(name: "entity", value: "movie")
        let termQuery = URLQueryItem(name: "term", value: term)
        
        urlComponents.queryItems?.append(mediaQuery)
        urlComponents.queryItems?.append(entityQuery)
        urlComponents.queryItems?.append(termQuery)
        
        let requestURL = urlComponents.url!
        
        let dataTask = session.dataTask(with: requestURL){data, response, error in
            let successRange = 200..<300
            guard error == nil, let statusCode = (response as? HTTPURLResponse)?.statusCode, successRange.contains(statusCode)else{
                completion([])
                return
            }
            guard let resultData = data else{
                completion([])
                return
            }
            //data -> Movie
            let movies = SearchAPI.parsMovies(resultData)
            completion(movies)
        }
        
        
        dataTask.resume()
    }
    static func parsMovies(_ data: Data)->[Movie]{
        let decoder = JSONDecoder()
        do{
            let response = try decoder.decode(Response.self, from: data)
            let movies = response.movies
            return movies
        }catch let error{
            print("---> parsing Error: \(error.localizedDescription)")
            return []
        }
    }
}

struct Response: Codable{//Json으로 내려오니까 Json을 ->Object로 Parsing 하기 위한것임
    let resultCount: Int
    let movies: [Movie]
    
    enum CodingKeys: String, CodingKey{
        case resultCount
        case movies = "results"
    }
}

struct Movie:Codable{
    let title: String
    let director: String
    let thumbnailPath: String
    let previewURL: String
    
    enum CodingKeys: String, CodingKey{
        case title = "trackName"
        case director = "artistName"
        case thumbnailPath = "artworkUrl100"
        case previewURL = "previewUrl"
    }
}

