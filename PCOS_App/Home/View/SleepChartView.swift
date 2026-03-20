//
//  SleepChartView.swift
//  PCOS_App
//
//  Created by SDC-USER on 12/02/26.
//

import SwiftUI
import Charts

struct SleepChartView: View {
    let dataPoints: [SleepChartDataModel]
    let timeRange: SleepChartTimeRange
    
    var body: some View {
        let validPoints = dataPoints.filter { $0.hours > 0 }
        let maxHours = validPoints.map(\.hours).max() ?? 0
        let yDomainMax = max(10.0, ceil(maxHours + 1.0))
        let average = validPoints.isEmpty ? 0 : validPoints.map(\.hours).reduce(0, +) / Double(validPoints.count)
        let avgHrs = Int(average)
        let avgMins = Int((average.truncatingRemainder(dividingBy: 1)) * 60)
        let step = yDomainMax > 12 ? 5.0 : 2.5
        let yValues = Array(stride(from: 0.0, through: yDomainMax, by: step))

        VStack(alignment: .leading, spacing: 0) {
            
            // Header mimicking Image 2
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Average")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B8B8B"))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(avgHrs)")
                            .font(.system(size: 28, weight: .bold))
                        Text("h")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B8B8B"))
                        Text("\(avgMins)")
                            .font(.system(size: 28, weight: .bold))
                        Text("m")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B8B8B"))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Goal")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8B8B8B"))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("8")
                            .font(.system(size: 20, weight: .bold))
                        Text("h")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#8B8B8B"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
            
            // Chart
            Chart {
                ForEach(dataPoints) { point in
                    BarMark(
                        x: .value("Time", point.date, unit: timeRange == .year ? .month : (timeRange == .month ? .weekOfYear : .day)),
                        y: .value("Hours", point.hours),
                        width: .ratio(0.6)
                    )
                    .foregroundStyle(barColor(for: point.hours))
                    .cornerRadius(6)
                }
                
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Color(hex: "#8B8B8B")) // Grey dashed line like image 2
            }
            .chartYScale(domain: 0...yDomainMax)
            .chartYAxis {
                AxisMarks(position: .leading, values: yValues) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)) // Solid thin lines
                        .foregroundStyle(Color.gray.opacity(0.15))
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))") // No 'h' unit
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#8B8B8B"))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom, values: dataPoints.map(\.date)) { value in
                    if let date = value.as(Date.self),
                       let point = dataPoints.first(where: { $0.date == date }) {
                        AxisValueLabel {
                            Text(point.label.prefix(3))
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#8B8B8B"))
                        }
                    }
                }
            }
            .frame(height: 200)
            .id(timeRange)
            .padding(.horizontal, 4)
            .padding(.bottom, 16)
        }
    }
    
    private func barColor(for hours: Double) -> Color {
        switch hours {
        case 7.5...10:
            return Color(hex: "#FE7A96")
        case 7.0..<7.5:
            return Color(hex: "#FE9BAD")
        case 6.0..<7.0:
            return Color(hex: "#FFC2D1")
        default:
            return Color(hex: "#FFE0E8")
        }
    }
}
