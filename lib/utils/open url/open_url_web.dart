import 'dart:html' as html;

void openUrl(String url) {
  final resolved = Uri.base.resolve(url).toString();
  html.window.open(resolved, '_blank');
}
