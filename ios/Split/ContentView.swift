import SwiftUI

struct ContentView: View {
    @State private var bill = ""
    @State private var tip = "20"
    @State private var people = 2
    @State private var peopleText = "2"
    @FocusState private var focus: Field?

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 64
    @ScaledMetric(relativeTo: .title) private var shareSize: CGFloat = 40
    @ScaledMetric(relativeTo: .title2) private var totalSize: CGFloat = 34
    @ScaledMetric(relativeTo: .title2) private var fieldSize: CGFloat = 34

    private var result: CheckSplit.Result {
        CheckSplit.calculate(bill: bill, tip: tip, people: people)
    }

    var body: some View {
        VStack(spacing: 0) {
            Color("Accent")
                .frame(height: 8)
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    results
                    billField
                    tipField
                    peopleField
                    Text("Nothing is saved or sent. It works offline.")
                        .font(.body)
                        .foregroundStyle(Color("Muted"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color("Canvas").ignoresSafeArea())
        .tint(Color("Accent"))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .onChange(of: focus) { old, _ in
            if old == .bill {
                let tidy = CheckSplit.tidyMoney(bill)
                if tidy != bill { bill = tidy }
            }
            if old == .tip {
                let tidy = CheckSplit.tidyPercent(tip)
                if tidy != tip { tip = tidy }
            }
            if old == .people {
                peopleText = String(people)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Split")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color("Ink"))
            Text("Split a restaurant check.")
                .font(.title3)
                .foregroundStyle(Color("Muted"))
        }
        .accessibilityElement(children: .combine)
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What each person pays")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("Muted"))

            if result.isEven {
                Text(CheckSplit.formatCents(result.shares.first ?? 0))
                    .font(.system(size: heroSize, weight: .bold))
                    .foregroundStyle(Color("Ink"))
                    .monospacedDigit()
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                Text(evenNote)
                    .font(.title3)
                    .foregroundStyle(Color("Muted"))
            } else {
                shareRow(count: result.higherCount, cents: result.shares[0])
                shareRow(count: result.people - result.higherCount, cents: result.shares[result.shares.count - 1])
                Text(unevenNote)
                    .font(.title3)
                    .foregroundStyle(Color("Muted"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 3) {
                Rectangle().fill(Color("Ink")).frame(height: 1)
                Rectangle().fill(Color("Ink")).frame(height: 1)
            }
            .padding(.top, 6)
            .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tip \(CheckSplit.formatPercent(result.basisPoints))")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("Muted"))
                    Text(CheckSplit.formatCents(result.tipCents))
                        .font(.system(size: totalSize, weight: .bold))
                        .foregroundStyle(Color("Ink"))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color("Muted"))
                    Text(CheckSplit.formatCents(result.totalCents))
                        .font(.system(size: totalSize, weight: .bold))
                        .foregroundStyle(Color("Ink"))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var evenNote: String {
        let who = result.people == 1 ? "One person" : "All \(result.people) people"
        return result.tipCents > 0 ? "\(who), tip included" : who
    }

    private var unevenNote: String {
        let sum = CheckSplit.formatCents(result.shares.reduce(0, +))
        let line = "Shares add up to \(sum)."
        return result.tipCents > 0 ? "Tip included. \(line)" : line
    }

    private func shareRow(count: Int, cents: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(count == 1 ? "1 person" : "\(count) people")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("Ink"))
            Spacer(minLength: 12)
            Text(CheckSplit.formatCents(cents))
                .font(.system(size: shareSize, weight: .bold))
                .foregroundStyle(Color("Ink"))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color("Line")).frame(height: 1)
        }
    }

    private var billField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("Ink"))
            HStack(spacing: 6) {
                Text("$")
                    .font(.system(size: fieldSize, weight: .bold))
                    .foregroundStyle(Color("Muted"))
                    .accessibilityHidden(true)
                TextField("0.00", text: $bill)
                    .textFieldStyle(.plain)
                    .keyboardType(.decimalPad)
                    .focused($focus, equals: .bill)
                    .font(.system(size: fieldSize, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color("Ink"))
                    .accessibilityLabel("Bill amount in dollars")
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 68)
            .background(Color("Field"))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Ink"), lineWidth: 2))
        }
        .onChange(of: bill) { _, newValue in
            let clean = CheckSplit.sanitizeMoney(newValue)
            if clean != newValue { bill = clean }
        }
    }

    private var tipField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tip")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("Ink"))
            HStack(spacing: 8) {
                ForEach(CheckSplit.presets, id: \.self) { preset in
                    let selected = !tip.isEmpty && CheckSplit.percentToBps(tip) == preset * 100
                    Button {
                        tip = String(preset)
                        focus = nil
                    } label: {
                        Text("\(preset)%")
                            .font(.title3.weight(.bold))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .foregroundStyle(selected ? Color("Card") : Color("Ink"))
                            .background(selected ? Color("Ink") : Color.clear)
                            .overlay(Capsule().stroke(Color("Ink"), lineWidth: 2))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(preset) percent")
                    .accessibilityAddTraits(selected ? .isSelected : AccessibilityTraits())
                }
            }
            Text("Or type a percent")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("Ink"))
                .padding(.top, 4)
            HStack(spacing: 6) {
                TextField("0", text: $tip)
                    .textFieldStyle(.plain)
                    .keyboardType(.decimalPad)
                    .focused($focus, equals: .tip)
                    .font(.system(size: fieldSize, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color("Ink"))
                    .accessibilityLabel("Tip percent")
                Text("%")
                    .font(.system(size: fieldSize, weight: .bold))
                    .foregroundStyle(Color("Muted"))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 68)
            .background(Color("Field"))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Ink"), lineWidth: 2))
        }
        .onChange(of: tip) { _, newValue in
            let clean = CheckSplit.sanitizePercent(newValue)
            if clean != newValue { tip = clean }
        }
    }

    private var peopleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("People")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color("Ink"))
            HStack(spacing: 10) {
                Button {
                    setPeople(people - 1)
                } label: {
                    Text("−")
                        .font(.system(size: 34, weight: .bold))
                        .frame(width: 68, height: 68)
                        .foregroundStyle(Color("Ink"))
                        .background(Color("Field"))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Ink"), lineWidth: 2))
                }
                .buttonStyle(.plain)
                .disabled(people <= 1)
                .accessibilityLabel("Fewer people")

                TextField("2", text: $peopleText)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .focused($focus, equals: .people)
                    .multilineTextAlignment(.center)
                    .font(.system(size: fieldSize, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color("Ink"))
                    .frame(maxWidth: .infinity, minHeight: 68)
                    .background(Color("Field"))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Ink"), lineWidth: 2))
                    .accessibilityLabel("Number of people")

                Button {
                    setPeople(people + 1)
                } label: {
                    Text("+")
                        .font(.system(size: 34, weight: .bold))
                        .frame(width: 68, height: 68)
                        .foregroundStyle(Color("Ink"))
                        .background(Color("Field"))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Ink"), lineWidth: 2))
                }
                .buttonStyle(.plain)
                .disabled(people >= CheckSplit.maxPeople)
                .accessibilityLabel("More people")
            }
        }
        .onChange(of: peopleText) { _, newValue in
            var digits = String(newValue.filter { $0 >= "0" && $0 <= "9" }.prefix(2))
            if digits.count > 1 {
                digits = String(digits.drop(while: { $0 == "0" }))
            }
            if digits != newValue { peopleText = digits }
            if digits == "0" {
                setPeople(1)
                return
            }
            if let value = Int(digits), (1...CheckSplit.maxPeople).contains(value) {
                people = value
            }
        }
    }

    private func setPeople(_ value: Int) {
        people = CheckSplit.clampPeople(value)
        peopleText = String(people)
    }
}

private enum Field: Hashable {
    case bill
    case tip
    case people
}

#Preview {
    ContentView()
}
