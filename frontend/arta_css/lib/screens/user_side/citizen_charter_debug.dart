
  Widget _buildDebugInfo(BuildContext context) {
    try {
      final surveyData = context.watch<SurveyProvider>().surveyData;
      return Text(
        "DEBUG: CC0=${surveyData.cc0Rating}",
        style: const TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.none),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
