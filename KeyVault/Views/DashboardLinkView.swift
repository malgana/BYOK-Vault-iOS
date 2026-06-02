//
//  DashboardLinkView.swift
//  KeyVault
//

import SwiftUI

struct DashboardLinkView: View {
    let urlString: String?

    var body: some View {
        if let urlString, let url = URL(string: urlString) {
            Link(destination: url) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline)
                    Text("Личный кабинет")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
