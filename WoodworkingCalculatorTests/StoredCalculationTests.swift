import Testing
import Foundation
@testable import Wood_Calc

@Suite
struct StoredCalculationTests {
    @Test
    func roundtripRealQuantity() throws {
        let originalQuantity = Quantity.real(12.5, Dimension(1))
        
        let result = StoredCalculation.Result.from(quantity: originalQuantity)
        let convertedQuantity = result.quantity
        
        #expect(convertedQuantity == originalQuantity)
    }
    
    @Test
    func roundtripRationalQuantity() throws {
        let rational = try! UncheckedRational(3, 4).checked.get()
        let originalQuantity = Quantity.rational(rational, Dimension(1))
        
        let result = StoredCalculation.Result.from(quantity: originalQuantity)
        let convertedQuantity = result.quantity
        
        #expect(convertedQuantity == originalQuantity)
    }
    
    @Test
    func encodeDecodeRealResult() throws {
        let original = StoredCalculation(
            input: "2.5 * 5",
            result: .real(12.5, 1),
            formattedResult: "12.5 in"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StoredCalculation.self, from: data)
        
        #expect(decoded.input == original.input)
        #expect(decoded.formattedResult == original.formattedResult)
        
        if case .real(let decodedValue, let decodedDim) = decoded.result,
           case .real(let originalValue, let originalDim) = original.result {
            #expect(decodedValue == originalValue)
            #expect(decodedDim == originalDim)
        } else {
            Issue.record("result type mismatch")
        }
    }
    
    @Test
    func encodeDecodeRationalResult() throws {
        let original = StoredCalculation(
            input: "1/2 + 1/4",
            result: .rational(3, 4, 1),
            formattedResult: "3/4 in"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StoredCalculation.self, from: data)
        
        #expect(decoded.input == original.input)
        #expect(decoded.formattedResult == original.formattedResult)
        
        if case .rational(let decodedNum, let decodedDen, let decodedDim) = decoded.result,
           case .rational(let originalNum, let originalDen, let originalDim) = original.result {
            #expect(decodedNum == originalNum)
            #expect(decodedDen == originalDen)
            #expect(decodedDim == originalDim)
        } else {
            Issue.record("result type mismatch")
        }
    }
}
