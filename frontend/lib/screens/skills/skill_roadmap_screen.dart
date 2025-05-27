import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:skill_sharing_app/models/skill_model.dart';
import 'package:skill_sharing_app/services/skill_service.dart';
import 'package:skill_sharing_app/theme/app_theme.dart';
import 'package:skill_sharing_app/utils/api_response.dart';
import 'package:skill_sharing_app/screens/skills/skill_detail_screen.dart';

class SkillRoadmapScreen extends StatefulWidget {
  final Skill skill;

  const SkillRoadmapScreen({
    Key? key,
    required this.skill,
  }) : super(key: key);

  @override
  _SkillRoadmapScreenState createState() => _SkillRoadmapScreenState();
}

class _SkillRoadmapScreenState extends State<SkillRoadmapScreen> {
  Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  bool _isLoading = true;
  String? _errorMessage;
  final _skillService = SkillService();

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _skillService.getSkillRoadmap(widget.skill.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _buildGraph(response.data!);
          } else {
            _errorMessage = response.error ?? 'Failed to load roadmap';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _buildGraph(Map<String, dynamic> roadmapData) {
    graph = Graph()..isTree = true;

    // Create root node
    final rootNode = Node.Id(widget.skill.id);
    graph.addNode(rootNode);

    // Add subskills
    for (var item in roadmapData['roadmap']) {
      final subskill = item['subskill'];
      final subskillNode = Node.Id(subskill['_id']);
      graph.addNode(subskillNode);
      graph.addEdge(rootNode, subskillNode);

      // Add nested subskills if any
      if (subskill['roadmap'] != null) {
        for (var nestedItem in subskill['roadmap']) {
          final nestedSubskill = nestedItem['subskill'];
          final nestedNode = Node.Id(nestedSubskill['_id']);
          graph.addNode(nestedNode);
          graph.addEdge(subskillNode, nestedNode);
        }
      }
    }

    // Configure graph layout
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.skill.name} Roadmap'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRoadmap,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.01,
                  maxScale: 5.6,
                  child: GraphView(
                    graph: graph,
                    algorithm: BuchheimWalkerAlgorithm(
                      builder,
                      TreeEdgeRenderer(builder),
                    ),
                    paint: Paint()
                      ..color = Colors.black
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      return _buildNodeWidget(node);
                    },
                  ),
                ),
    );
  }

  Widget _buildNodeWidget(Node node) {
    // Find the skill data for this node
    final skillData = _findSkillData(node.key?.value);
    if (skillData == null) return const SizedBox();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SkillDetailScreen(
              skill: Skill.fromJson(skillData),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              skillData['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (skillData['proficiency'] != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getProficiencyColor(skillData['proficiency'])
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  skillData['proficiency'],
                  style: TextStyle(
                    color: _getProficiencyColor(skillData['proficiency']),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _findSkillData(String? nodeId) {
    if (nodeId == widget.skill.id) {
      return {
        'id': widget.skill.id,
        'name': widget.skill.name,
        'proficiency': widget.skill.proficiency,
      };
    }

    // Search in roadmap data
    for (var item in widget.skill.roadmap ?? []) {
      if (item['subskill']['_id'] == nodeId) {
        return item['subskill'];
      }
      // Search in nested roadmap
      if (item['subskill']['roadmap'] != null) {
        for (var nestedItem in item['subskill']['roadmap']) {
          if (nestedItem['subskill']['_id'] == nodeId) {
            return nestedItem['subskill'];
          }
        }
      }
    }
    return null;
  }

  Color _getProficiencyColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }
}
