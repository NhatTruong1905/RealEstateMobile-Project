part of '../ChatScreen.dart';

extension ChatView on _ChatScreenState {
  Widget _buildPage(BuildContext context) {
    final bool isSeller = _isSellerUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1918),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF4EEE6),
              child: Text(
                _targetReceiverName.isNotEmpty
                    ? _targetReceiverName.substring(0, 1).toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Color(0xFF945331),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _targetReceiverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1918),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor:
                            _connState == ChatConnectionState.connected
                            ? const Color(0xFF2E7D32)
                            : _connState == ChatConnectionState.connecting
                            ? const Color(0xFFE65100)
                            : const Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _connState == ChatConnectionState.connected
                            ? 'Trực tuyến'
                            : _connState == ChatConnectionState.connecting
                            ? 'Đang kết nối...'
                            : 'Ngoại tuyến',
                        style: TextStyle(
                          fontSize: 11,
                          color: _connState == ChatConnectionState.connected
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF78736D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF4EEE6),
              border: Border(bottom: BorderSide(color: Color(0xFFE8E3DC))),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      (widget.property.image != null &&
                          widget.property.image!.isNotEmpty)
                      ? Image.network(
                          widget.property.image!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 48,
                                height: 48,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.home, size: 24),
                              ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.home, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.property.title ?? 'Bất động sản',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A1918),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatPropertyPrice(widget.property.price),
                        style: const TextStyle(
                          color: Color(0xFF945331),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _fullyAccepted
                  ? const Color(0xFFECFDF5)
                  : (_myAccept || _partnerAccept
                        ? const Color(0xFFFFFBEB)
                        : const Color(0xFFFAF5EF)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _fullyAccepted
                    ? const Color(0xFFA7F3D0)
                    : (_myAccept || _partnerAccept
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFE8DFD5)),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _fullyAccepted
                        ? const Color(0xFFD1FAE5)
                        : (_myAccept || _partnerAccept
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF3E8DC)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _fullyAccepted
                        ? Icons.task_alt_rounded
                        : (_myAccept || _partnerAccept
                              ? Icons.timer_outlined
                              : Icons.edit_calendar_rounded),
                    color: _fullyAccepted
                        ? const Color(0xFF059669)
                        : (_myAccept || _partnerAccept
                              ? const Color(0xFFD97706)
                              : const Color(0xFF945331)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _fullyAccepted
                                  ? 'Đã chốt lịch & lưu hệ thống'
                                  : (_myAccept && _partnerAccept
                                        ? 'Cả 2 bên đã đồng ý!'
                                        : (_myAccept
                                              ? 'Đã gửi yêu cầu xác nhận'
                                              : (_partnerAccept
                                                    ? 'Đối phương đã chấp nhận!'
                                                    : 'Xác nhận hẹn xem BĐS'))),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _fullyAccepted
                                    ? const Color(0xFF065F46)
                                    : (_myAccept || _partnerAccept
                                          ? const Color(0xFF92400E)
                                          : const Color(0xFF1A1918)),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((_myAccept || _partnerAccept) &&
                              !_fullyAccepted) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatCountdown(_remainingSeconds),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fullyAccepted
                            ? (isSeller
                                  ? 'Đã hẹn lịch xem nhà'
                                  : 'Lịch xem nhà đã được chốt')
                            : (_myAccept
                                  ? 'Chờ đối phương xác nhận (15p)'
                                  : (_partnerAccept
                                        ? 'Nhấn chấp nhận để chốt lịch'
                                        : 'Thống nhất và chốt lịch xem nhà')),
                        style: TextStyle(
                          fontSize: 11,
                          color: _fullyAccepted
                              ? const Color(0xFF047857)
                              : (_myAccept || _partnerAccept
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF78736D)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSubmittingAppointment
                      ? null
                      : (_fullyAccepted
                            ? (isSeller ? _completePropertyViewing : null)
                            : (_myAccept
                                  ? _cancelPropertyViewing
                                  : _acceptPropertyViewing)),
                  icon: _isSubmittingAppointment
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _fullyAccepted
                              ? (isSeller
                                    ? Icons.task_alt_rounded
                                    : Icons.verified_rounded)
                              : (_myAccept
                                    ? Icons.cancel_outlined
                                    : (_partnerAccept
                                          ? Icons.mark_email_unread_rounded
                                          : Icons.approval_rounded)),
                          size: 15,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isSubmittingAppointment
                        ? 'Đang xử lý...'
                        : (_fullyAccepted
                              ? (isSeller ? 'Đã xem nhà xong' : 'Hoàn tất')
                              : (_myAccept
                                    ? 'Hủy yêu cầu'
                                    : (_partnerAccept
                                          ? 'Đồng ý hẹn xem nhà'
                                          : 'Hẹn đi xem nhà'))),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _fullyAccepted
                        ? (isSeller
                              ? const Color(0xFF059669)
                              : const Color(0xFF059669))
                        : (_myAccept
                              ? const Color(0xFFDC2626)
                              : (_partnerAccept
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF945331))),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF945331)),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Color(0xFF78736D),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hãy bắt đầu cuộc trò chuyện với $_targetReceiverName',
                          style: const TextStyle(
                            color: Color(0xFF78736D),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.getSenderId == _myUserId;

                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn tư vấn...',
                        filled: true,
                        fillColor: const Color(0xFFF4EEE6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF945331),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
