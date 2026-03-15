import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/member_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  String? _churchCode;
  final Set<String> _prayingSent = {};

  @override
  void initState() {
    super.initState();
    _loadChurchCode();
  }

  Future<void> _loadChurchCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _churchCode = prefs.getString('church_code'));
  }

  Future<void> _editBirthday(MemberModel member) async {
    DateTime selected = DateTime(
      DateTime.now().year,
      member.birthMonth ?? DateTime.now().month,
      member.birthDay ?? 1,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: '생일 선택',
      fieldLabelText: '생일',
    );
    if (picked == null || !mounted) return;
    await MemberService.updateBirthday(
      churchCode: _churchCode!,
      uid: member.uid,
      birthMonth: picked.month,
      birthDay: picked.day,
      birthYear: picked.year,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎂 ${member.name}님 생일 저장 완료 (${picked.month}/${picked.day})'),
        backgroundColor: const Color(0xFF1565C0),
      ),
    );
  }

  Future<void> _sendPrayer(MemberModel member) async {
    if (_prayingSent.contains(member.uid)) return;
    setState(() => _prayingSent.add(member.uid));

    final success = await MemberService.sendPrayerNotification(
      memberUid: member.uid,
      churchCode: _churchCode!,
      memberName: member.name,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🙏 ${member.name}님께 기도 알림을 보냈습니다'),
          backgroundColor: const Color(0xFF1565C0),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _prayingSent.remove(member.uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name}님의 알림 설정이 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교인 목록'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _churchCode == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<MemberModel>>(
              stream: MemberService.membersStream(_churchCode!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = snapshot.data ?? [];
                if (members.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('등록된 교인이 없습니다',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('교인이 앱에 로그인하면 자동 등록됩니다',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final member = members[i];
                    final alreadySent = _prayingSent.contains(member.uid);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1565C0),
                        child: Text(
                          member.name.isNotEmpty ? member.name[0] : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(member.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${member.role} · ${member.email}'),
                          if (member.birthdayText.isNotEmpty)
                            Text('🎂 ${member.birthdayText}',
                                style: const TextStyle(fontSize: 12, color: Colors.orange)),
                          if (member.birthdayText.isEmpty)
                            GestureDetector(
                              onTap: () => _editBirthday(member),
                              child: const Text('+ 생일 등록',
                                  style: TextStyle(fontSize: 12, color: Colors.blue)),
                            ),
                        ],
                      ),
                      onTap: () => _editBirthday(member),
                      trailing: alreadySent
                          ? const Chip(
                              label: Text('전송완료',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white)),
                              backgroundColor: Color(0xFF1565C0),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _sendPrayer(member),
                              icon: const Text('🙏', style: TextStyle(fontSize: 14)),
                              label: const Text('기도했습니다'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1565C0),
                                side: const BorderSide(color: Color(0xFF1565C0)),
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                    );
                  },
                );
              },
            ),
    );
  }
}
