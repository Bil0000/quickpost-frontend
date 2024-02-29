String formatNumber(int? count) {
  if (count! >= 1000 && count < 1000000) {
    int thousands = count ~/ 1000;
    int remainder = count % 1000;

    // Calculate how many hundreds are in the remainder
    int hundredsInRemainder =
        (remainder / 100).floor(); // Use floor to avoid rounding up

    // For numbers exactly at thousand or when there's no hundred in remainder, show without decimal
    if (remainder == 0 || hundredsInRemainder == 0) {
      return '${thousands}K';
    } else {
      // Otherwise, show the decimal representing the hundred's place
      return '$thousands.${hundredsInRemainder}K';
    }
  } else if (count >= 1000000) {
    // Apply similar logic for millions if necessary, adjusted for the scale
    int millions = count ~/ 1000000;
    int remainder = count % 1000000;
    int hundredThousandsInRemainder =
        (remainder / 100000).floor(); // Adjust for million scale

    if (remainder == 0 || hundredThousandsInRemainder == 0) {
      return '${millions}M';
    } else {
      return '$millions.${hundredThousandsInRemainder}M';
    }
  } else {
    return count.toString();
  }
}
