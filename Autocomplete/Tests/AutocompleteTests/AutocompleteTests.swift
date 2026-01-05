import Testing
@testable import Autocomplete

@MainActor
@Suite
struct AutocompleterTests {

    @Test("Autocompleter completes with the correct suffix")
    func returnsSuffixForSimplePrefixMatch() {
        let autocompleter = Autocompleter(candidates: ["apple", "banana"])
        let result = autocompleter.complete("app")

        #expect(result == "le")
    }

    @Test("Autocompleter is case insensitive")
    func isCaseInsensitive() {
        let autocompleter = Autocompleter(candidates: ["Apple"])
        let result = autocompleter.complete("ap")

        #expect(result == "ple")
    }

    @Test("Exact matches do not autocomplete")
    func exactMatchDoesNotAutocomplete() {
        let autocompleter = Autocompleter(candidates: ["apple"])
        let result = autocompleter.complete("apple")

        #expect(result == nil)
    }

    @Test("Autocompleter finds no match when none are present")
    func returnsNilWhenNoCandidatesMatch() {
        let autocompleter = Autocompleter(candidates: ["apple", "banana"])
        let result = autocompleter.complete("car")

        #expect(result == nil)
    }

    @Test("Autocompleter completes with the first matching candidate")
    func usesFirstMatchingCandidate() {
        let autocompleter = Autocompleter(candidates: ["application", "apple"])
        let result = autocompleter.complete("app")

        #expect(result == "lication")
    }

    @Test("Empty candidates list doesn't match anything")
    func emptyCandidatesReturnsNil() {
        let autocompleter = Autocompleter(candidates: [])
        let result = autocompleter.complete("app")

        #expect(result == nil)
    }
}
