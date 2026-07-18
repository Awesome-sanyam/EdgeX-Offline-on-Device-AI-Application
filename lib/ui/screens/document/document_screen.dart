import 'package:flutter/material.dart';

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mock PDF Area
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 200),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend\nArchitecture\nConstraints &\nGuidelines v2.4', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Approved', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      const Text('Last updated: Oct 24, 2023', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', style: TextStyle(fontSize: 16, color: Color(0xFF334155), height: 1.6)),
                ],
              ),
            ),
          ),
        ),
        
        // Floating AI Sheet
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
                        SizedBox(width: 12),
                        Expanded(child: Text('This document outlines the backend architecture constraints.', style: TextStyle(color: Color(0xFF1E293B)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: const Row(
                      children: [
                        Expanded(child: TextField(decoration: InputDecoration(hintText: 'Ask a question...', border: InputBorder.none))),
                        CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.arrow_upward, color: Color(0xFF94A3B8), size: 18))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}