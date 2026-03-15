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
  final Set<String> _prayingSent = {}; // 이미 보낸 알림 (중복 방지)

  @override
  void initState() {
    super.initState();
    _loadChurchCode();
  }

  Future<void> _loadChurchCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _churchCode = prefs.getString('church_code'));
  }

  void _showMemberOptions(MemberModel member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(member.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1A6B3A)),
              title: const Text('이름 / 직분 수정'),
              onTap: () { Navigator.pop(context); _editMemberInfo(member); },
            ),
            ListTile(
              leading: const Icon(Icons.cake, color: Colors.orange),
              title: Text(member.birthdayText.isNotEmpty ? '생일 수정 (${member.birthdayText})' : '생일 등록'),
              onTap: () { Navigator.pop(context); _editBirthday(member); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editMemberInfo(MemberModel member) async {
    final nameCtrl = TextEditingController(text: member.name);
    const roles = ['성도', '집사', '권사', '장로', '목사', '전도사'];
    String selectedRole = roles.contains(member.role) ? member.role : '성도';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('교인 정보 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder()),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: '직분', border: OutlineInputBorder()),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setS(() => selectedRole = v ?? selectedRole),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6B3A)),
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;
    await MemberService.updateMemberInfo(
      churchCode: _churchCode!,
      uid: member.uid,
      name: newName,
      role: selectedRole,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ $newName님 정보가 수정됐습니다'), backgroundColor: const Color(0xFF1A6B3A)),
    );
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
        backgroundColor: const Color(0xFF1A6B3A),
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
          backgroundColor: const Color(0xFF1A6B3A),
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
        backgroundColor: const Color(0xFF1A6B3A),
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
                        backgroundColor: const Color(0xFF1A6B3A),
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
                              onTap: () => _showMemberOptions(member),
                              child: const Text('+ 생일 등록',
                                  style: TextStyle(fontSize: 12, color: Colors.blue)),
                            ),
                        ],
                      ),
                      onTap: () => _showMemberOptions(member),
                      trailing: alreadySent
                          ? const Chip(
                              label: Text('전송완료',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white)),
                              backgroundColor: Color(0xFF1A6B3A),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _sendPrayer(member),
                              icon: const Text('🙏',
                                  style: TextStyle(fontSize: 14)),
                              label: const Text('기도했습니다'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1A6B3A),
                                side: const BorderSide(
                                    color: Color(0xFF1A6B3A)),
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
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
