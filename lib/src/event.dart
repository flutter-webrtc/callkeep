abstract class EventType {
  EventType();
  void sanityCheck() {}
}

/// This class serves as a Typed event bus.
///
/// Events can be subscribed to by calling the "on" method.
///
/// Events are distributed by calling the "emit" method.
///
/// Subscribers my unsubscrive by calling "remove" with both the EventType and the callback function that was
/// originally subscribed with.
///
/// Subscribers will implement a callback function taking exactly one argument of the same type as the
/// Event they wish to receive.
///
/// Thus:
///
/// on(EventCallState(),(EventCallState event){
///  -- do something here
/// });
class EventManager {
  Map<Type, List<dynamic>> listeners = <Type, List<dynamic>>{};

  /// returns true if there are any listeners associated with the EventType for this instance of EventManager
  bool hasListeners(EventType event) {
    final targets = listeners[event.runtimeType];
    if (targets != null) {
      return targets.isNotEmpty;
    }
    return false;
  }

  /// call "on" to subscribe to events of a particular type
  ///
  /// Subscribers will implement a callback function taking exactly one argument of the same type as the
  /// Event they wish to receive.
  ///
  /// Thus:
  ///
  /// on(EventCallState(),(EventCallState event){
  ///  -- do something here
  /// });
  void on<T extends EventType>(T eventType, void Function(T event) listener) {
    assert(listener != null, 'Null listener');
    assert(eventType != null, 'Null eventType');
    _addListener(eventType.runtimeType, listener);
  }

  /// It isn't possible to have type constraints here on the listener,
  /// BUT very importantly this method is private and
  /// all the methods that call it enforce the types!!!!
  void _addListener(Type runtimeType, dynamic listener) {
    assert(listener != null, 'Null listener');
    assert(runtimeType != null, 'Null runtimeType');
    try {
      var targets = listeners[runtimeType];
      if (targets == null) {
        targets = <dynamic>[];
        listeners[runtimeType] = targets;
      }
      targets.remove(listener);
      targets.add(listener);
    } catch (e) {
      rethrow;
    }
  }

  /// add all event handlers from an other instance of EventManager to this one.
  void addAllEventHandlers(EventManager other) {
    other.listeners.forEach((Type runtimeType, List<dynamic> otherListeners) {
      // ignore: avoid_function_literals_in_foreach_calls
      otherListeners.forEach((dynamic otherListener) {
        _addListener(runtimeType, otherListener);
      });
    });
  }

  void remove<T extends EventType>(
      T eventType, void Function(T event) listener) {
    final targets = listeners[eventType.runtimeType];
    if (targets == null) {
      return;
    }
    //    logger.warn("removing $eventType on $listener");
    if (!targets.remove(listener)) {
      print('Failed to remove any listeners for EventType $eventType');
    }
  }

  /// send the supplied event to all of the listeners that are subscribed to that EventType
  void emit<T extends EventType>(T event) {
    event.sanityCheck();
    // ignore: always_specify_types
    final targets = listeners[event.runtimeType];

    if (targets != null) {
      // avoid concurrent modification
      final copy = List<dynamic>.from(targets);
      // ignore: avoid_function_literals_in_foreach_calls
      copy.forEach((dynamic target) {
        try {
          //   logger.warn("invoking $event on $target");
          target(event);
        } catch (e) {
          rethrow;
        }
      });
    }
  }
}
