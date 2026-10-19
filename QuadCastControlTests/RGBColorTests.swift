import Testing
@testable import QuadCastControl

struct RGBColorTests {
    @Test func zeroPercentProducesBlack() {
        let color = RGBColor(red: 255, green: 127, blue: 1)
        #expect(color.scaled(byPercent: 0) == RGBColor(red: 0, green: 0, blue: 0))
    }

    @Test func fullBrightnessPreservesEveryChannel() {
        let color = RGBColor(red: 1, green: 127, blue: 254)
        #expect(color.scaled(byPercent: 100) == color)
    }

    @Test func halfBrightnessRoundsToNearestWithHalvesUp() {
        let color = RGBColor(red: 255, green: 3, blue: 254)
        #expect(color.scaled(byPercent: 50) == RGBColor(red: 128, green: 2, blue: 127))
    }

    @Test func roundingWorksBelowAtAndAboveHalfAChannelStep() {
        let color = RGBColor(red: 49, green: 50, blue: 51)
        #expect(color.scaled(byPercent: 1) == RGBColor(red: 0, green: 1, blue: 1))
    }

    @Test(arguments: [150, Int.max])
    func percentagesAboveOneHundredClampWithoutOverflow(percent: Int) {
        let color = RGBColor(red: 255, green: 127, blue: 1)
        #expect(color.scaled(byPercent: percent) == color)
    }

    @Test(arguments: [-10, Int.min])
    func negativePercentagesClampWithoutOverflow(percent: Int) {
        let color = RGBColor(red: 255, green: 127, blue: 1)
        #expect(color.scaled(byPercent: percent) == RGBColor(red: 0, green: 0, blue: 0))
    }
}
