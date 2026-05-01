import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../services/account_deletion_service.dart';
import '../../../auth/login.dart';
import '../../../shared/utils.dart';

class UserSettingsScreen extends StatefulWidget {
  final String gymId;
  final String userName;
  final String? photoUrl;

  const UserSettingsScreen({
    super.key,
    required this.gymId,
    required this.userName,
    this.photoUrl,
  });

  @override
  State<UserSettingsScreen> createState() =>
      _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _user = FirebaseAuth.instance.currentUser!;
  bool _isDeletingAccount = false;
  bool _uploadingPhoto    = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.photoUrl;
  }

  // ── Profile picture ──────────────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 600,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final file = File(picked.path);
      final ref  = FirebaseStorage.instance
          .ref('profile_pictures/${_user.uid}.jpg');

      await ref.putFile(
          file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({'photoUrl': url});

      // Sync to member subcollection so owner/staff can see it
      try {
        await FirebaseFirestore.instance
            .collection('gyms')
            .doc(widget.gymId)
            .collection('members')
            .doc(_user.uid)
            .update({'photoUrl': url});
      } catch (_) {}

      if (mounted) setState(() => _photoUrl = url);
      if (mounted) {
        _showSnackBar('Profile picture updated!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Upload failed: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final ok = await showConfirmDialog(
      context: context,
      title: 'Remove Photo',
      message: 'Remove your profile picture?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({'photoUrl': FieldValue.delete()});

      try {
        await FirebaseFirestore.instance
            .collection('gyms')
            .doc(widget.gymId)
            .collection('members')
            .doc(_user.uid)
            .update({'photoUrl': FieldValue.delete()});
      } catch (_) {}

      try {
        await FirebaseStorage.instance
            .ref('profile_pictures/${_user.uid}.jpg')
            .delete();
      } catch (_) {}

      if (mounted) setState(() => _photoUrl = null);
      if (mounted) {
        _showSnackBar('Profile picture removed', Colors.white54);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Account deletion ─────────────────────────────────────────────────────────

  Future<void> _initiateDeleteAccount() async {
    if (_isDeletingAccount) return;

    final step1 = await showConfirmDialog(
      context: context,
      title: 'Delete Account',
      message:
          'This will permanently delete your account and anonymize your personal '
          'data. Your attendance and payment history will remain for gym records, '
          'but your name and contact info will be removed. This cannot be undone.',
      confirmLabel: 'Continue',
      isDestructive: true,
    );
    if (!step1 || !mounted) return;

    final svc = AccountDeletionService();
    String feeStatus = 'unknown';
    try {
      feeStatus =
          await svc.getMemberFeeStatus(widget.gymId, _user.uid) ??
              'unknown';
    } catch (_) {
      _showSnackBar(
          'Could not verify fee status. Try again.', Colors.redAccent);
      return;
    }

    final hasOutstandingFees =
        feeStatus == 'unpaid' || feeStatus == 'pending';
    if (hasOutstandingFees && mounted) {
      final step2 = await showConfirmDialog(
        context: context,
        title: 'Outstanding Fees',
        message:
            'You have $feeStatus fees. Your gym owner will be notified about '
            'this deletion. Do you still want to proceed?',
        confirmLabel: 'Delete Anyway',
        isDestructive: true,
      );
      if (!step2 || !mounted) return;
    }

    if (!mounted) return;
    final reauthed = await _showPasswordConfirmDialog(svc);
    if (!reauthed || !mounted) return;

    setState(() => _isDeletingAccount = true);

    try {
      await svc.deleteMemberAccount(
        gymId:      widget.gymId,
        uid:        _user.uid,
        memberName: widget.userName,
        feeStatus:  feeStatus,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Login()),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
            'Account deletion failed. Please try again.',
            Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Future<bool> _showPasswordConfirmDialog(
      AccountDeletionService svc) async {
    final passCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Your Identity',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your password to permanently delete your account.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Delete',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    try {
      await svc.reauthenticate(
          email: _user.email ?? '', password: passCtrl.text);
      return true;
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'wrong-password' ||
                e.code == 'invalid-credential'
            ? 'Incorrect password.'
            : 'Authentication failed. Please try again.';
        _showSnackBar(msg, Colors.redAccent);
      }
      return false;
    } catch (_) {
      if (mounted) {
        _showSnackBar(
            'Authentication failed. Please try again.',
            Colors.redAccent);
      }
      return false;
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        children: [

          // ── Profile picture ────────────────────────────────────────────
          _sectionLabel('PROFILE PICTURE'),
          const SizedBox(height: 12),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Avatar
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellowAccent.withOpacity(0.1),
                    border: Border.all(
                        color: Colors.yellowAccent.withOpacity(0.3),
                        width: 2),
                  ),
                  child: _uploadingPhoto
                      ? const Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.yellowAccent),
                        )
                      : _photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _photoUrl!,
                                fit: BoxFit.cover,
                                width: 96,
                                height: 96,
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatar(),
                              ),
                            )
                          : _defaultAvatar(),
                ),

                // Camera button
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0A0A0A), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.black, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
              child: const Text('Upload Photo',
                  style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
            if (_photoUrl != null) ...[
              const Text('·', style: TextStyle(color: Colors.white24)),
              TextButton(
                onPressed: _uploadingPhoto ? null : _removePhoto,
                child: const Text('Remove',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 13)),
              ),
            ],
          ]),
          const SizedBox(height: 24),

          // ── Account info ───────────────────────────────────────────────
          _sectionLabel('ACCOUNT'),
          const SizedBox(height: 10),
          _InfoTile(
            label: 'Email',
            value: _user.email ?? '—',
            icon:  Icons.email_outlined,
          ),
          const SizedBox(height: 6),
          _InfoTile(
            label: 'Name',
            value: widget.userName,
            icon:  Icons.person_outline_rounded,
          ),

          const SizedBox(height: 32),

          // ── Danger zone ────────────────────────────────────────────────
          _sectionLabel('DANGER ZONE'),
          const SizedBox(height: 10),
          _isDeletingAccount
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        color: Colors.redAccent),
                  ),
                )
              : _DangerItem(
                  icon:     Icons.delete_forever_rounded,
                  label:    'Delete Account',
                  subtitle: 'Permanently remove your account and data',
                  onTap:    _initiateDeleteAccount,
                ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() => Center(
        child: Icon(Icons.fitness_center_rounded,
            color: Colors.yellowAccent.withOpacity(0.6), size: 36),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8)),
      );
}

// ─── Info tile ────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white38, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      );
}

// ─── Danger item ──────────────────────────────────────────────────────────────

class _DangerItem extends StatelessWidget {
  const _DangerItem(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.redAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.redAccent, size: 20),
            ]),
          ),
        ),
      );
}
