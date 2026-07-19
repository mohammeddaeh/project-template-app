extension IntEx on int {
  String get getTimeFromIntSeconds {
    Duration duration = Duration(seconds: this);
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours != "00") {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  String getPlus() {
    if (this > 99) {
      return "+99";
    }
    if (this > 9) {
      return "+9";
    }
    return toString();
  }

  /*
 * To format any int number to 1M or 2.5K
 */
  String get formatNumber {
    if (this >= 1000000) {
      double result = this / 1000000.0;
      return '${result.toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      double result = this / 1000.0;
      return '${result.toStringAsFixed(1)}K';
    } else {
      return toString();
    }
  }

  String get formatFileSize {
    const int kb = 1024;
    const int mb = 1024 * 1024;

    if (this >= mb) {
      double sizeInMb = this / mb;
      return '${sizeInMb.toStringAsFixed(1)} MB';
    } else if (this >= kb) {
      double sizeInKb = this / kb;
      return '${sizeInKb.toStringAsFixed(1)} KB';
    } else {
      return '$this bytes';
    }
  }
}

extension DoubleEx on double {
  String get formatNumber {
    String roundedNum = toStringAsFixed(2);
    if (roundedNum.contains('.')) {
      roundedNum = roundedNum.replaceAll(RegExp(r'0*$'), '');
      if (roundedNum.endsWith('.')) {
        roundedNum = roundedNum.substring(0, roundedNum.length - 1);
      }
    }

    return roundedNum;
  }
}
