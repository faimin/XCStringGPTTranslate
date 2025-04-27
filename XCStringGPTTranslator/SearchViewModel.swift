//
//  SearchViewModel.swift
//  XCStringGPTTranslator
//
//  Created by Zero_D_Saber on 2025/4/27.
//

import Combine
import Foundation

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    /// limit the search speed
    @Published var debounceSearchText: String = ""
    
    init() {
        $searchText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .assign(to: &($debounceSearchText))
    }
}
