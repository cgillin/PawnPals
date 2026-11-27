import Foundation

/// Where Stockfish's two neural-network files are inside the app.
///
/// They're downloaded by `scripts/fetch-stockfish-networks.sh` and packaged with
/// PittChessCore as resources. If the names change here, change them in the script too.
struct StockfishNetworks {
    static let mainName = "nn-1111cefa1111"
    static let smallName = "nn-37f18f62d772"

    /// File path of the main network.
    let main: String
    /// File path of the small network, used for lopsided positions.
    let small: String

    /// Finds both files, or throws if either one is missing.
    static func locate() throws -> StockfishNetworks {
        StockfishNetworks(main: try path(of: mainName), small: try path(of: smallName))
    }

    private static func path(of name: String) throws -> String {
        guard
            let url = Bundle.module.url(
                forResource: name, withExtension: "nnue", subdirectory: "Networks")
        else { throw EngineError.missingNetworkFile("\(name).nnue") }
        return url.path(percentEncoded: false)
    }
}
