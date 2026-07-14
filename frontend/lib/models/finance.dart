class FinancesSummary {
  final BankDetails? bankDetails;
  final StatutoryInfo? statutoryInfo;
  final IdentityInfo? identity;

  FinancesSummary({
    this.bankDetails,
    this.statutoryInfo,
    this.identity,
  });

  factory FinancesSummary.fromJson(Map<String, dynamic> json) {
    return FinancesSummary(
      bankDetails: json['bank_details'] != null ? BankDetails.fromJson(json['bank_details']) : null,
      statutoryInfo: json['statutory_info'] != null ? StatutoryInfo.fromJson(json['statutory_info']) : null,
      identity: json['identity'] != null ? IdentityInfo.fromJson(json['identity']) : null,
    );
  }
}

class BankDetails {
  final int id;
  final String accountNo;
  final String ifsc;
  final String bankName;

  BankDetails({
    required this.id,
    required this.accountNo,
    required this.ifsc,
    required this.bankName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      id: json['id'],
      accountNo: json['account_no'] ?? '',
      ifsc: json['ifsc'] ?? '',
      bankName: json['bank_name'] ?? '',
    );
  }
}

class StatutoryInfo {
  final int id;
  final String? pfAccount;
  final String? esiStatus;
  final String? ptState;
  final String lwfStatus;

  StatutoryInfo({
    required this.id,
    this.pfAccount,
    this.esiStatus,
    this.ptState,
    required this.lwfStatus,
  });

  factory StatutoryInfo.fromJson(Map<String, dynamic> json) {
    return StatutoryInfo(
      id: json['id'],
      pfAccount: json['pf_account'],
      esiStatus: json['esi_status'],
      ptState: json['pt_state'],
      lwfStatus: json['lwf_status'] ?? 'Disabled',
    );
  }
}

class IdentityInfo {
  final String? pan;
  final String? aadhaar;
  final String dob;
  final String personalEmail;

  IdentityInfo({
    this.pan,
    this.aadhaar,
    required this.dob,
    required this.personalEmail,
  });

  factory IdentityInfo.fromJson(Map<String, dynamic> json) {
    return IdentityInfo(
      pan: json['pan'],
      aadhaar: json['aadhaar'],
      dob: json['dob'] ?? '',
      personalEmail: json['personal_email'] ?? '',
    );
  }
}

class Payslip {
  final int id;
  final int payrollRunId;
  final int employeeId;
  final double gross;
  final double deductions;
  final double netPay;
  final String? pdfUrl;
  final int month;
  final int year;
  final String runStatus;

  Payslip({
    required this.id,
    required this.payrollRunId,
    required this.employeeId,
    required this.gross,
    required this.deductions,
    required this.netPay,
    this.pdfUrl,
    required this.month,
    required this.year,
    required this.runStatus,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['id'],
      payrollRunId: json['payroll_run_id'],
      employeeId: json['employee_id'],
      gross: double.tryParse(json['gross'].toString()) ?? 0.0,
      deductions: double.tryParse(json['deductions'].toString()) ?? 0.0,
      netPay: double.tryParse(json['net_pay'].toString()) ?? 0.0,
      pdfUrl: json['pdf_url'],
      month: json['month'] ?? 1,
      year: json['year'] ?? 2026,
      runStatus: json['run_status'] ?? 'Draft',
    );
  }
}
