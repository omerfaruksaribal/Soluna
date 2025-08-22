import TipKit

struct FirstRunTip: Tip {
    var title: Text {
        Text("Add your first mood")
    }

    var message: Text? {
        Text("See your trend in the chart.")
    }

    var image: Image? {
        Image(systemName: "face.smiling")
    }
}
