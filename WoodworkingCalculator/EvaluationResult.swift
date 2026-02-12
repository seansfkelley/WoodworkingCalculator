struct EvaluationResult {
    let quantity: Quantity
    let noUnitsSpecified: Bool

    func assumingLength(if condition: Bool) -> Quantity {
        condition && noUnitsSpecified ? quantity.withDimension(.length) : quantity
    }
}
