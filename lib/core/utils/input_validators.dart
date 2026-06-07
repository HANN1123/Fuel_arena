class InputValidators {
  const InputValidators._();

  static const _blockedPlaceholders = {
    'test',
    '테스트',
    'asdf',
    'qwer',
    'admin',
    '관리자',
    'null',
  };

  static String? nickname(String value) {
    final text = value.trim();
    if (text.length < 2) {
      return '닉네임은 2자 이상 입력해 주세요.';
    }
    if (text.length > 16) {
      return '닉네임은 16자 이하로 입력해 주세요.';
    }
    if (_isPlaceholder(text)) {
      return '실제로 사용할 닉네임을 입력해 주세요.';
    }
    return null;
  }

  static String? vehicleNickname(String value) {
    final text = value.trim();
    if (text.length < 2) {
      return '차량 별명은 2자 이상 입력해 주세요.';
    }
    if (text.length > 20) {
      return '차량 별명은 20자 이하로 입력해 주세요.';
    }
    return null;
  }

  static String? supportTitle(String value) {
    final text = value.trim();
    if (text.length < 2) {
      return '제목은 2자 이상 입력해 주세요.';
    }
    if (text.length > 60) {
      return '제목은 60자 이하로 입력해 주세요.';
    }
    if (_isPlaceholder(text)) {
      return '문의 제목을 구체적으로 입력해 주세요.';
    }
    return null;
  }

  static String? supportBody(String value) {
    final text = value.trim();
    if (text.length < 5) {
      return '내용은 5자 이상 입력해 주세요.';
    }
    if (text.length > 1200) {
      return '내용은 1200자 이하로 입력해 주세요.';
    }
    if (_isPlaceholder(text)) {
      return '문제 상황을 조금 더 자세히 적어 주세요.';
    }
    return null;
  }

  static String? couponCode(String value) {
    final text = value.trim().toUpperCase();
    if (text.isEmpty) {
      return '쿠폰 코드를 입력해 주세요.';
    }
    if (!RegExp(r'^[A-Z0-9-]{4,24}$').hasMatch(text)) {
      return '쿠폰 코드는 영문, 숫자, 하이픈만 사용할 수 있어요.';
    }
    return null;
  }

  static String? positiveFuelAmount(String value,
      {required String fuelLeague}) {
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return fuelLeague == 'electric'
          ? '전력 사용량을 0보다 크게 입력해 주세요.'
          : '연료 사용량을 0보다 크게 입력해 주세요.';
    }
    if (fuelLeague == 'electric' && amount > 250) {
      return '전력 사용량이 너무 커요. 입력값을 확인해 주세요.';
    }
    if (fuelLeague != 'electric' && amount > 200) {
      return '연료 사용량이 너무 커요. 입력값을 확인해 주세요.';
    }
    return null;
  }

  static bool _isPlaceholder(String value) {
    final normalized = value.trim().toLowerCase();
    return _blockedPlaceholders.contains(normalized);
  }
}
