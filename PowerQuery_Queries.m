// PERSONAL FINANCES — HOUSEHOLD POWER QUERY
// Source: local folder containing subfolders "Revolut Dan" and "Revolut Anca".
// Create each query below as a separate blank query with the exact name shown.
// qTransactionsRaw is the source query; qTransactionsCategorized references it.

// ============================================================================
// QUERY: qTransactionsRaw
// ============================================================================
let
    SettingsTable = Excel.CurrentWorkbook(){[Name="tblSettings"]}[Content],
    FolderPath = Text.Trim(Text.From(SettingsTable{[Setting="ImportFolder"]}[Value])),
    AccountMap = Excel.CurrentWorkbook(){[Name="tblAccounts"]}[Content],
    SourceFiles = Folder.Files(FolderPath),
    CsvFiles = Table.SelectRows(SourceFiles, each Text.Lower([Extension]) = ".csv" and not Text.StartsWith([Name], "~$")),
    AddAccount = Table.AddColumn(CsvFiles, "Account", each
        let
            FP = Text.Lower([Folder Path]),
            Matches = Table.SelectRows(AccountMap, (r) => Text.Contains(FP, Text.Lower(Text.From(r[FolderName]))) and r[Include] = true)
        in
            if Table.RowCount(Matches) = 0 then null else Text.From(Matches{0}[Account]), type text),
    RecognizedFiles = Table.SelectRows(AddAccount, each [Account] <> null),
    ReadCsv = Table.AddColumn(RecognizedFiles, "Rows", each
        let
            AccountName = [Account],
            SourceName = [Name],
            Csv = Csv.Document([Content], [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
            Promoted = Table.PromoteHeaders(Csv, [PromoteAllScalars=true]),
            TrimmedHeaders = Table.TransformColumnNames(Promoted, each Text.Trim(_)),
            AddAccountColumn = Table.AddColumn(TrimmedHeaders, "Account", each AccountName, type text),
            AddSourceColumn = Table.AddColumn(AddAccountColumn, "SourceFile", each SourceName, type text)
        in
            AddSourceColumn),
    Expanded = Table.ExpandTableColumn(ReadCsv, "Rows",
        {"Type","Product","Started Date","Completed Date","Description","Amount","Fee","Currency","State","Balance","Account","SourceFile"},
        {"Type","Product","Started Date","Completed Date","Description","Amount","Fee","Currency","State","Balance","Account","SourceFile"}),
    KeepColumns = Table.SelectColumns(Expanded,
        {"Account","SourceFile","Type","Product","Started Date","Completed Date","Description","Amount","Fee","Currency","State","Balance"}),
    Typed = Table.TransformColumns(KeepColumns, {
        {"Account", each Text.Trim(Text.From(_)), type text},
        {"SourceFile", each Text.Trim(Text.From(_)), type text},
        {"Type", each if _ = null then "" else Text.Trim(Text.From(_)), type text},
        {"Product", each if _ = null then "" else Text.Trim(Text.From(_)), type text},
        {"Started Date", each try if _ = null or Text.Trim(Text.From(_)) = "" then null else DateTime.FromText(Text.Trim(Text.From(_)), [Culture="en-US"]) otherwise null, type nullable datetime},
        {"Completed Date", each try if _ = null or Text.Trim(Text.From(_)) = "" then null else DateTime.FromText(Text.Trim(Text.From(_)), [Culture="en-US"]) otherwise null, type nullable datetime},
        {"Description", each if _ = null then "" else Text.Trim(Text.From(_)), type text},
        {"Amount", each try Number.FromText(Text.Trim(Text.From(_)), "en-US") otherwise null, type nullable number},
        {"Fee", each try Number.FromText(Text.Trim(Text.From(_)), "en-US") otherwise 0, type number},
        {"Currency", each if _ = null then "" else Text.Upper(Text.Trim(Text.From(_))), type text},
        {"State", each if _ = null then "" else Text.Upper(Text.Trim(Text.From(_))), type text},
        {"Balance", each try Number.FromText(Text.Trim(Text.From(_)), "en-US") otherwise null, type nullable number}
    }),
    AddPostingDate = Table.AddColumn(Typed, "PostingDate", each
        if [Completed Date] <> null then Date.From([Completed Date])
        else if [Started Date] <> null then Date.From([Started Date]) else null, type nullable date),
    AddMonthStart = Table.AddColumn(AddPostingDate, "MonthStart", each if [PostingDate] = null then null else Date.StartOfMonth([PostingDate]), type nullable date),
    AddNetCash = Table.AddColumn(AddMonthStart, "NetCashAmount", each (if [Amount] = null then 0 else [Amount]) - (if [Fee] = null then 0 else [Fee]), type number),
    AddFingerprint = Table.AddColumn(AddNetCash, "Fingerprint", each
        Text.Combine({
            [Account],
            if [Completed Date] <> null then DateTime.ToText([Completed Date], "yyyy-MM-dd HH:mm:ss") else if [Started Date] <> null then DateTime.ToText([Started Date], "yyyy-MM-dd HH:mm:ss") else "NO_DATE",
            [Type], Text.Upper(Text.Trim([Description])),
            Number.ToText(if [Amount] = null then 0 else [Amount], "0.00", "en-US"),
            Number.ToText(if [Fee] = null then 0 else [Fee], "0.00", "en-US"), [Currency]
        }, "|"), type text),
    DuplicateCounts = Table.Group(AddFingerprint, {"Fingerprint"}, {{"PossibleDuplicateCount", each Table.RowCount(_), Int64.Type}}),
    JoinDuplicateCounts = Table.NestedJoin(AddFingerprint, {"Fingerprint"}, DuplicateCounts, {"Fingerprint"}, "DuplicateInfo", JoinKind.LeftOuter),
    ExpandDuplicateCounts = Table.ExpandTableColumn(JoinDuplicateCounts, "DuplicateInfo", {"PossibleDuplicateCount"}, {"PossibleDuplicateCount"}),
    AddDuplicateFlag = Table.AddColumn(ExpandDuplicateCounts, "PossibleDuplicate", each [PossibleDuplicateCount] > 1, type logical),
    AddYear = Table.AddColumn(AddDuplicateFlag, "Year", each if [PostingDate] = null then null else Date.Year([PostingDate]), Int64.Type),
    AddMonthNo = Table.AddColumn(AddYear, "MonthNo", each if [PostingDate] = null then null else Date.Month([PostingDate]), Int64.Type)
in
    AddMonthNo

// ============================================================================
// QUERY: qTransactionsCategorized
// ============================================================================
let
    Source = qTransactionsRaw,
    RulesTable = Excel.CurrentWorkbook(){[Name="tblMerchantRules"]}[Content],
    ActiveRules = Table.SelectRows(RulesTable, each [Active] = true and [MatchText] <> null and Text.Trim(Text.From([MatchText])) <> ""),
    SortedRules = Table.Sort(ActiveRules, {{"Priority", Order.Ascending}}),
    Rules = Table.ToRecords(SortedRules),
    AddMatchedRule = Table.AddColumn(Source, "MatchedRule", each
        let
            DescriptionUpper = Text.Upper(Text.From([Description])),
            Matches = List.Select(Rules, (r) => Text.Contains(DescriptionUpper, Text.Upper(Text.From(r[MatchText]))))
        in
            if List.Count(Matches) = 0 then null else Matches{0}, type any),
    AddCategory = Table.AddColumn(AddMatchedRule, "Category", each
        if [MatchedRule] <> null then Text.From([MatchedRule][Category])
        else if [Type] = "Card Payment" or [Type] = "Fee" or [Type] = "Charge" or [Type] = "WERO_PAYMENT" then "Unclassified"
        else if [Type] = "Card Refund" then "Refunds"
        else if [Type] = "Transfer" then "Transfer review"
        else if [Type] = "Deposit" or [Type] = "Topup" then "Income review"
        else if [Type] = "Exchange" then "Currency exchange"
        else "Other review", type text),
    AddFlowTreatment = Table.AddColumn(AddCategory, "FlowTreatment", each
        if [State] <> "COMPLETED" then "Excluded"
        else if [MatchedRule] <> null then Text.From([MatchedRule][FlowTreatment])
        else if [Type] = "Card Payment" or [Type] = "Fee" or [Type] = "Charge" or [Type] = "WERO_PAYMENT" then "Expense"
        else if [Type] = "Card Refund" then "Refund"
        else if [Type] = "Transfer" then "Transfer review"
        else if [Type] = "Deposit" or [Type] = "Topup" then "Income review"
        else if [Type] = "Exchange" then "Currency exchange"
        else "Review", type text),
    AddExpenseAmount = Table.AddColumn(AddFlowTreatment, "ExpenseAmount", each if [State] = "COMPLETED" and [FlowTreatment] = "Expense" then List.Max({0, -[NetCashAmount]}) else 0, type number),
    AddRefundAmount = Table.AddColumn(AddExpenseAmount, "RefundAmount", each if [State] = "COMPLETED" and [FlowTreatment] = "Refund" then List.Max({0, [NetCashAmount]}) else 0, type number),
    AddIncomeAmount = Table.AddColumn(AddRefundAmount, "IncomeAmount", each if [State] = "COMPLETED" and [FlowTreatment] = "Income" then List.Max({0, [NetCashAmount]}) else 0, type number),
    AddIncomeReview = Table.AddColumn(AddIncomeAmount, "IncomeReviewInflow", each if [State] = "COMPLETED" and [FlowTreatment] = "Income review" then List.Max({0, [NetCashAmount]}) else 0, type number),
    AddInternalIn = Table.AddColumn(AddIncomeReview, "InternalTransferIn", each if [State] = "COMPLETED" and [FlowTreatment] = "Internal transfer" then List.Max({0, [NetCashAmount]}) else 0, type number),
    AddInternalOut = Table.AddColumn(AddInternalIn, "InternalTransferOut", each if [State] = "COMPLETED" and [FlowTreatment] = "Internal transfer" then List.Max({0, -[NetCashAmount]}) else 0, type number),
    AddInvestmentOut = Table.AddColumn(AddInternalOut, "InvestmentContribution", each if [State] = "COMPLETED" and [FlowTreatment] = "Investment" then List.Max({0, -[NetCashAmount]}) else 0, type number),
    AddMortgageOut = Table.AddColumn(AddInvestmentOut, "MortgageReviewOut", each if [State] = "COMPLETED" and [FlowTreatment] = "Mortgage review" then List.Max({0, -[NetCashAmount]}) else 0, type number),
    AddTransferReviewOut = Table.AddColumn(AddMortgageOut, "UnclassifiedTransferOut", each if [State] = "COMPLETED" and [FlowTreatment] = "Transfer review" then List.Max({0, -[NetCashAmount]}) else 0, type number)
in
    AddTransferReviewOut

// ============================================================================
// QUERY: qMonthlySummary
// ============================================================================
let
    Source = qTransactionsCategorized,
    Grouped = Table.Group(Source, {"MonthStart", "Year", "MonthNo"}, {
        {"Income", each List.Sum([IncomeAmount]), type number},
        {"IncomeReviewInflow", each List.Sum([IncomeReviewInflow]), type number},
        {"Expenses", each List.Sum([ExpenseAmount]), type number},
        {"Refunds", each List.Sum([RefundAmount]), type number},
        {"InternalTransferIn", each List.Sum([InternalTransferIn]), type number},
        {"InternalTransferOut", each List.Sum([InternalTransferOut]), type number},
        {"InvestmentContributions", each List.Sum([InvestmentContribution]), type number},
        {"MortgageReviewOut", each List.Sum([MortgageReviewOut]), type number},
        {"UnclassifiedTransferOut", each List.Sum([UnclassifiedTransferOut]), type number},
        {"TransactionCount", each Table.RowCount(Table.SelectRows(_, each [State] = "COMPLETED")), Int64.Type},
        {"PossibleDuplicateRows", each Table.RowCount(Table.SelectRows(_, each [State] = "COMPLETED" and [PossibleDuplicate] = true)), Int64.Type},
        {"PendingOrRevertedExcluded", each Table.RowCount(Table.SelectRows(_, each [State] <> "COMPLETED")), Int64.Type}
    }),
    AddNetSpend = Table.AddColumn(Grouped, "NetSpend", each [Expenses] - [Refunds], type number),
    CurrentDate = Date.From(DateTime.LocalNow()),
    AddPartialFlag = Table.AddColumn(AddNetSpend, "IsPartialMonth", each [Year] = Date.Year(CurrentDate) and [MonthNo] = Date.Month(CurrentDate), type logical),
    Reorder = Table.ReorderColumns(AddPartialFlag, {"MonthStart","Year","MonthNo","Income","IncomeReviewInflow","Expenses","Refunds","NetSpend","InternalTransferIn","InternalTransferOut","InvestmentContributions","MortgageReviewOut","UnclassifiedTransferOut","TransactionCount","PossibleDuplicateRows","PendingOrRevertedExcluded","IsPartialMonth"}),
    Sorted = Table.Sort(Reorder, {{"MonthStart", Order.Ascending}})
in
    Sorted

// ============================================================================
// QUERY: qCategoryMonthly
// ============================================================================
let
    Source = qTransactionsCategorized,
    InScope = Table.SelectRows(Source, each [State] = "COMPLETED" and ([FlowTreatment] = "Expense" or [FlowTreatment] = "Refund") and [MonthStart] <> null),
    Grouped = Table.Group(InScope, {"MonthStart","Year","MonthNo","Category"}, {
        {"Expenses", each List.Sum([ExpenseAmount]), type number},
        {"Refunds", each List.Sum([RefundAmount]), type number},
        {"TransactionCount", each Table.RowCount(_), Int64.Type}
    }),
    AddNetSpend = Table.AddColumn(Grouped, "NetSpend", each [Expenses] - [Refunds], type number),
    AddPriorYear = Table.AddColumn(AddNetSpend, "PriorYear", each [Year] - 1, Int64.Type),
    JoinPrior = Table.NestedJoin(AddPriorYear, {"PriorYear","MonthNo","Category"}, AddNetSpend, {"Year","MonthNo","Category"}, "Prior", JoinKind.LeftOuter),
    ExpandPrior = Table.ExpandTableColumn(JoinPrior, "Prior", {"NetSpend"}, {"PriorYearSpend"}),
    AddYoYChange = Table.AddColumn(ExpandPrior, "YoYChange", each if [PriorYearSpend] = null then null else [NetSpend] - [PriorYearSpend], type nullable number),
    AddYoYPercent = Table.AddColumn(AddYoYChange, "YoYChangePct", each if [PriorYearSpend] = null or [PriorYearSpend] = 0 then null else [YoYChange] / [PriorYearSpend], type nullable number),
    CurrentYear = Date.Year(Date.From(DateTime.LocalNow())),
    HistoricalOnly = Table.SelectRows(AddNetSpend, each [Year] < CurrentYear and [Year] >= CurrentYear - 3),
    Seasonal = Table.Group(HistoricalOnly, {"MonthNo","Category"}, {{"SameMonth3YearAvg", each if Table.RowCount(_) = 0 then null else List.Average([NetSpend]), type nullable number}}),
    JoinSeasonal = Table.NestedJoin(AddYoYPercent, {"MonthNo","Category"}, Seasonal, {"MonthNo","Category"}, "Seasonal", JoinKind.LeftOuter),
    ExpandSeasonal = Table.ExpandTableColumn(JoinSeasonal, "Seasonal", {"SameMonth3YearAvg"}, {"SameMonth3YearAvg"}),
    AddSeasonalVariance = Table.AddColumn(ExpandSeasonal, "VsSeasonalAvgPct", each if [Year] <> CurrentYear or [SameMonth3YearAvg] = null or [SameMonth3YearAvg] = 0 then null else ([NetSpend] - [SameMonth3YearAvg]) / [SameMonth3YearAvg], type nullable number),
    Reorder = Table.ReorderColumns(AddSeasonalVariance, {"MonthStart","Year","MonthNo","Category","Expenses","Refunds","NetSpend","TransactionCount","PriorYearSpend","YoYChange","YoYChangePct","SameMonth3YearAvg","VsSeasonalAvgPct"}),
    Sorted = Table.Sort(Reorder, {{"MonthStart", Order.Ascending},{"Category",Order.Ascending}})
in
    Sorted

// ============================================================================
// QUERY: qRecurringCandidates
// ============================================================================
let
    Source = qTransactionsCategorized,
    ExpensesOnly = Table.SelectRows(Source, each [State] = "COMPLETED" and [FlowTreatment] = "Expense" and [ExpenseAmount] > 0 and [PostingDate] <> null),
    AddMerchantKey = Table.AddColumn(ExpensesOnly, "MerchantKey", each Text.Upper(Text.Trim([Description])), type text),
    Grouped = Table.Group(AddMerchantKey, {"Category","MerchantKey"}, {{"Rows", each _, type table}}),
    AddStats = Table.AddColumn(Grouped, "Stats", each
        let
            T = Table.Sort([Rows], {{"PostingDate", Order.Ascending}}),
            Dates = List.Sort(List.Distinct(Table.Column(T, "PostingDate"))),
            Amounts = Table.Column(T, "ExpenseAmount"),
            N = List.Count(Dates),
            Gaps = if N < 2 then {} else List.Transform({1..N-1}, (i) => Duration.Days(Dates{i} - Dates{i-1})),
            AvgGap = if List.Count(Gaps) = 0 then null else List.Average(Gaps),
            AvgAmount = if List.Count(Amounts) = 0 then null else List.Average(Amounts),
            MinAmount = if List.Count(Amounts) = 0 then null else List.Min(Amounts),
            MaxAmount = if List.Count(Amounts) = 0 then null else List.Max(Amounts),
            Frequency =
                if N = 1 then "Single occurrence"
                else if N >= 4 and AvgGap >= 5 and AvgGap <= 9 then "Weekly"
                else if N >= 3 and AvgGap >= 24 and AvgGap <= 38 then "Monthly"
                else if N >= 3 and AvgGap >= 75 and AvgGap <= 110 then "Quarterly"
                else if N >= 2 and AvgGap >= 160 and AvgGap <= 200 then "Semi-annual"
                else if N >= 2 and AvgGap >= 330 and AvgGap <= 400 then "Annual"
                else "Irregular / review",
            CycleMonths = if Frequency = "Weekly" then 0.23 else if Frequency = "Monthly" then 1 else if Frequency = "Quarterly" then 3 else if Frequency = "Semi-annual" then 6 else if Frequency = "Annual" then 12 else null,
            MonthlyEquivalent = if CycleMonths = null or AvgAmount = null then null else if Frequency = "Weekly" then AvgAmount * 4.33 else AvgAmount / CycleMonths,
            LastDate = if N = 0 then null else List.Last(Dates),
            NextDate = if CycleMonths = null or LastDate = null then null else if Frequency = "Weekly" then Date.AddDays(LastDate, 7) else Date.AddMonths(LastDate, Number.RoundDown(CycleMonths)),
            Confidence = if Frequency = "Monthly" and N >= 6 then "High" else if Frequency = "Annual" and N >= 3 then "High" else if Frequency = "Quarterly" and N >= 4 then "High" else if List.Contains({"Monthly","Quarterly","Semi-annual","Annual","Weekly"}, Frequency) then "Medium" else "Low",
            SuggestedAction = if Frequency = "Single occurrence" then "Review as possible one-off" else if Frequency = "Annual" then "Add to annual expense calendar" else if Frequency = "Irregular / review" then "Review payment pattern" else "Confirm recurring commitment"
        in
            [TransactionCount=Table.RowCount(T), FirstSeen=if N=0 then null else List.First(Dates), LastSeen=LastDate, AverageAmount=AvgAmount, MinAmount=MinAmount, MaxAmount=MaxAmount, AverageGapDays=AvgGap, FrequencyEstimate=Frequency, MonthlyEquivalent=MonthlyEquivalent, NextExpectedDate=NextDate, Confidence=Confidence, SuggestedAction=SuggestedAction], type record),
    ExpandStats = Table.ExpandRecordColumn(AddStats, "Stats", {"TransactionCount","FirstSeen","LastSeen","AverageAmount","MinAmount","MaxAmount","AverageGapDays","FrequencyEstimate","MonthlyEquivalent","NextExpectedDate","Confidence","SuggestedAction"}, {"TransactionCount","FirstSeen","LastSeen","AverageAmount","MinAmount","MaxAmount","AverageGapDays","FrequencyEstimate","MonthlyEquivalent","NextExpectedDate","Confidence","SuggestedAction"}),
    RemoveRows = Table.RemoveColumns(ExpandStats, {"Rows"}),
    Sorted = Table.Sort(RemoveRows, {{"FrequencyEstimate",Order.Ascending},{"MonthlyEquivalent",Order.Descending}})
in
    Sorted

// ============================================================================
// QUERY: qTransferReview
// ============================================================================
let
    Source = qTransactionsCategorized,
    ReviewRows = Table.SelectRows(Source, each [State] = "COMPLETED" and List.Contains({"Transfer review","Income review","Mortgage review","Review"}, [FlowTreatment])),
    Selected = Table.SelectColumns(ReviewRows, {"PostingDate","Account","Type","Description","Amount","Fee","NetCashAmount","Category","FlowTreatment","PossibleDuplicate","SourceFile"}),
    Renamed = Table.RenameColumns(Selected, {{"PostingDate","Date"}}),
    Sorted = Table.Sort(Renamed, {{"Date",Order.Descending},{"Account",Order.Ascending}})
in
    Sorted

// ============================================================================
// QUERY: qInsights
// ============================================================================
let
    SettingsTable = Excel.CurrentWorkbook(){[Name="tblSettings"]}[Content],
    AlertPct = Number.From(SettingsTable{[Setting="AlertPct"]}[Value]),
    AlertAmount = Number.From(SettingsTable{[Setting="AlertAmountEUR"]}[Value]),
    AsOfDate = Date.From(DateTime.LocalNow()),
    AnalysisMonth = Date.StartOfMonth(Date.AddMonths(AsOfDate, -1)),
    CurrentMonthRows = Table.SelectRows(qCategoryMonthly, each [Year] = Date.Year(AnalysisMonth) and [MonthNo] = Date.Month(AnalysisMonth) and [YoYChange] <> null and [YoYChange] >= AlertAmount and [YoYChangePct] >= AlertPct),
    YoySelect = Table.SelectColumns(CurrentMonthRows, {"Category","YoYChange","YoYChangePct"}),
    YoyMessage = Table.AddColumn(YoySelect, "Date", each AsOfDate, type date),
    YoySignal = Table.AddColumn(YoyMessage, "Signal", each "Same-month spending increase", type text),
    YoyText = Table.AddColumn(YoySignal, "Message", each [Category] & " is up " & Number.ToText([YoYChangePct]*100,"0.0") & "% versus the same month last year.", type text),
    YoyAction = Table.AddColumn(YoyText, "Action", each "Check whether this is a price rise, higher usage or a one-off.", type text),
    YoyImpact = Table.RenameColumns(YoyAction, {{"YoYChange","ImpactEUR"}}),
    YoyFinal = Table.SelectColumns(YoyImpact, {"Date","Signal","Category","Message","ImpactEUR","Action"}),
    Recurring = qRecurringCandidates,
    AnnualDue = Table.SelectRows(Recurring, each [FrequencyEstimate] = "Annual" and [NextExpectedDate] <> null and [NextExpectedDate] >= AsOfDate and [NextExpectedDate] <= Date.AddDays(AsOfDate,45)),
    AnnualDate = Table.AddColumn(AnnualDue, "Date", each [NextExpectedDate], type date),
    AnnualSignal = Table.AddColumn(AnnualDate, "Signal", each "Annual payment approaching", type text),
    AnnualMessage = Table.AddColumn(AnnualSignal, "Message", each [MerchantKey] & " may be due around " & Date.ToText([NextExpectedDate],"dd MMM yyyy") & ".", type text),
    AnnualImpact = Table.RenameColumns(AnnualMessage, {{"AverageAmount","ImpactEUR"}}),
    AnnualAction = Table.AddColumn(AnnualImpact, "Action", each "Confirm the renewal amount and reserve the cash.", type text),
    AnnualFinal = Table.SelectColumns(AnnualAction, {"Date","Signal","Category","Message","ImpactEUR","Action"}),
    OneOffs = Table.SelectRows(Recurring, each [FrequencyEstimate] = "Single occurrence" and [AverageAmount] <> null and [AverageAmount] >= AlertAmount),
    OneOffDate = Table.AddColumn(OneOffs, "Date", each [LastSeen], type date),
    OneOffSignal = Table.AddColumn(OneOffDate, "Signal", each "Large single expense", type text),
    OneOffMessage = Table.AddColumn(OneOffSignal, "Message", each [MerchantKey] & " appears once in the imported history; confirm whether it is exceptional or recurring.", type text),
    OneOffImpact = Table.RenameColumns(OneOffMessage, {{"AverageAmount","ImpactEUR"}}),
    OneOffAction = Table.AddColumn(OneOffImpact, "Action", each "Decide whether to exclude from the recurring baseline or add to an annual plan.", type text),
    OneOffFinal = Table.SelectColumns(OneOffAction, {"Date","Signal","Category","Message","ImpactEUR","Action"}),
    Combined = Table.Combine({YoyFinal,AnnualFinal,OneOffFinal}),
    Sorted = Table.Sort(Combined, {{"Date",Order.Ascending},{"Signal",Order.Ascending}})
in
    Sorted
