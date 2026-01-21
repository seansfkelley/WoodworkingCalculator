import Testing
@testable import Wood_Calc

@Suite
struct DimensionTests {
    @Test
    func staticValues() {
        #expect(Dimension.unitless.value == 0)
        #expect(Dimension.length.value == 1)
    }
    
    @Test
    func addSameDimensions() {
        #expect(Dimension(2) + Dimension(2) == .success(Dimension(2)))
    }
    
    @Test
    func addUnitlessAdoptsOther() {
        #expect(Dimension.unitless + Dimension.length == .success(Dimension.length))
        #expect(Dimension.length + Dimension.unitless == .success(Dimension.length))
    }
    
    @Test
    func addIncompatibleFails() {
        #expect(Dimension(1) + Dimension(2) == .failure(.incompatibleUnits))
    }
    
    @Test
    func subtractSameDimensions() {
        #expect(Dimension(3) - Dimension(3) == .success(Dimension(3)))
    }
    
    @Test
    func subtractIncompatibleFails() {
        #expect(Dimension(2) - Dimension(1) == .failure(.incompatibleUnits))
    }
    
    @Test
    func multiplyAddsExponents() {
        #expect(Dimension(1) * Dimension(2) == .success(Dimension(3)))
        #expect(Dimension(-1) * Dimension(1) == .success(Dimension(0)))
    }
    
    @Test
    func divideSubtractsExponents() {
        #expect(Dimension(2) / Dimension(1) == .success(Dimension(1)))
        #expect(Dimension(1) / Dimension(2) == .success(Dimension(-1)))
    }
}
