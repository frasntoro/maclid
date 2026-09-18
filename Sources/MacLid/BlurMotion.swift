/// How the blur makes its way down the screen as the lid closes.
enum BlurMotion: Int, CaseIterable {
    /// Every row mists over on its own, the top a little ahead of the bottom.
    case mist
    /// A soft front descends from the top edge, like a curtain being drawn.
    case curtain

    var label: String {
        switch self {
        case .mist: return "Mist"
        case .curtain: return "Curtain"
        }
    }
}
