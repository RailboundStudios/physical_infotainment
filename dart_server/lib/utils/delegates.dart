

/// Event system

class ListenerReceipt<T> {
  Function(T) listener;

  ListenerReceipt(this.listener);
}

class EventDelegate<T> {
 final List<ListenerReceipt<T>> _receipts = [];

  ListenerReceipt<T> addListener(Function(T) listener) {
    final receipt = ListenerReceipt(listener);
    _receipts.add(receipt);
    return receipt;
  }

  void removeListener(ListenerReceipt<T> receipt) {
    _receipts.remove(receipt);
    print("removed listener");
  }

  void trigger(T event) {
    print("triggering event");
    try {
      for (var receipt in _receipts) {
        print("triggering listener");
        try {
          receipt.listener(event);
        } catch (e) {
        }
      }
    } catch (e) {
      print("Error in trigger: $e");
    }
  }
}