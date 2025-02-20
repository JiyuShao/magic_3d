/*
 * @Description: 请补充模块描述
 * 
 * @Author: Jin
 * @Date: 2025-02-15 13:56:23
 * 
 * Copyright © 2014-2025 Rabbitpre.com. All Rights Reserved.
 */

import 'package:flutter/material.dart';

class CardGridItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onImageTap;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  const CardGridItem({
    Key? key,
    required this.imageUrl,
    required this.onImageTap,
    required this.onCopy,
    required this.onDelete,
  }) : super(key: key);

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        content: const Text(
          '是否删除该模型？',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.only(bottom: 12, right: 12, left: 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '删除',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 缩略图区域
          Expanded(
            child: GestureDetector(
              onTap: onImageTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // 按钮区域
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 下载按钮
                Expanded(
                  child: TextButton(
                    onPressed: onCopy,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.copy, size: 20),
                  ),
                ),
                // 分隔线
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.grey[300],
                ),
                // 删除按钮
                Expanded(
                  child: TextButton(
                    onPressed: () => _showDeleteDialog(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.delete_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
