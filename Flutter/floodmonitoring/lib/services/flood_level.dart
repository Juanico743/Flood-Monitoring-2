
String getStatusText(int value) {
  if (value >= 175) {
    return 'Safe';
  } else if (value >= 125 && value <= 174) {
    return 'Warning';
  } else {
    return 'Danger';
  }
}