import Foundation

/// Local, deterministic calculations for a static vertical hitch or a symmetric
/// two-leg bridle. Bridle angles are measured from horizontal, with equal load
/// sharing and the center of gravity midway between pick points.
struct CalculationEngine: CalculationEngineProtocol {
    func calculate(input: LiftInput) -> Result<CalculationResult, CalculationError> {
        guard input.loadWeightLb.isFinite, input.loadWeightLb > 0,
              input.slingRatedCapacityLb.isFinite, input.slingRatedCapacityLb > 0 else {
            return .failure(.invalidNumber)
        }

        let multiplier: Double
        let loadPerLeg: Double
        switch input.configuration {
        case .verticalHitch:
            guard input.angleDegrees == nil else { return .failure(.unexpectedAngle) }
            multiplier = 1
            loadPerLeg = input.loadWeightLb
        case .twoLegBridle:
            guard let angle = input.angleDegrees else { return .failure(.missingAngle) }
            guard angle.isFinite else { return .failure(.invalidNumber) }
            guard (30...90).contains(angle) else {
                return .failure(.angleOutOfSupportedRange)
            }
            // Exact endpoints avoid rounding 30 degrees above a factor of 2,
            // which would falsely classify an exactly rated load as overloaded.
            if angle == 30 {
                multiplier = 2
            } else if angle == 90 {
                multiplier = 1
            } else {
                multiplier = 1 / sin(angle * .pi / 180)
            }
            loadPerLeg = input.loadWeightLb / 2
        }

        let tension = loadPerLeg * multiplier
        let utilization = tension / input.slingRatedCapacityLb
        guard loadPerLeg.isFinite, loadPerLeg > 0,
              tension.isFinite, tension > 0,
              utilization.isFinite, utilization > 0 else {
            return .failure(.invalidNumber)
        }
        let withinCapacity = tension <= input.slingRatedCapacityLb
        var warnings = ["Academic prototype: have a qualified person verify results before lift planning."]
        if input.configuration == .twoLegBridle {
            warnings.append("Assumes equal load sharing, equal sling angles from horizontal, and a centered load. Dynamic and unequal loads are not modeled.")
        }
        if !withinCapacity {
            warnings.append("Calculated tension exceeds the supplied per-leg rated capacity.")
        }
        return .success(CalculationResult(
            angleMultiplier: multiplier,
            loadPerLegLb: loadPerLeg,
            tensionPerLegLb: tension,
            utilization: utilization,
            withinRatedCapacity: withinCapacity,
            warnings: warnings
        ))
    }
}
