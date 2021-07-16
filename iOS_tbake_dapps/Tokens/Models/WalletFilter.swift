// Copyright © 2018 Stormbird PTE. LTD.

import Foundation

enum WalletFilter {
    case type(Set<TokenType>)
	case tokenOnly
	case collectiblesOnly
	case keyword(String)
}

func == (lhs: WalletFilter, rhs: WalletFilter) -> Bool {
	switch (lhs, rhs) {
	case (.tokenOnly, .tokenOnly):
		return true
	case (.collectiblesOnly, .collectiblesOnly):
		return true
	case (.keyword(let keyword1), .keyword(let keyword2)):
		return keyword1 == keyword2
	case (.keyword, .tokenOnly), (.keyword, .collectiblesOnly), (.collectiblesOnly, .tokenOnly), (.collectiblesOnly, .keyword), (.tokenOnly, .collectiblesOnly), (.tokenOnly, .keyword):
        return false
	case (.type, _), (_, .type):
        return true
	}
}

