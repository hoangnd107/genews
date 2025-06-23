import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:provider/provider.dart';

class NewsAnalysisScreen extends StatefulWidget {
  final Result newsData;
  const NewsAnalysisScreen({super.key, required this.newsData});

  @override
  State<NewsAnalysisScreen> createState() => _NewsAnalysisScreenState();
}

class _NewsAnalysisScreenState extends State<NewsAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  _fetchAnalysis() {
    context.read<NewsProvider>().generateAnalysis(widget.newsData.description ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tóm tắt tin tức"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, newsState, child) {
          if (newsState.newsAnalysisState == ViewState.busy) {
            return Center(child: CircularProgressIndicator());
          }
          if ((newsState.analysis).isEmpty || newsState.newsAnalysisState == ViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    "Lỗi khi lấy kết quả.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Kiểm tra lại kết nối và thử lại.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchAnalysis,
                    icon: Icon(Icons.refresh),
                    label: Text("Thử lại"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(widget.newsData.title ?? "", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Divider(),
                  const SizedBox(height: 8),
                  if (widget.newsData.imageUrl != null)
                    Image.network(
                      widget.newsData.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    ),
                  const SizedBox(height: 8),
                  Divider(),
                  const SizedBox(height: 10),
                  // buildSection("Nội dung tóm tắt", newsState.analysis),
                  Text(newsState.analysis, style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => ContentCreationScreen(analysis: newsState.analysis)),
                        // );
                      },
                      label: Text("Hỏi thêm về bài báo"),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
