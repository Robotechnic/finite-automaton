# finite-automaton
A simple language to define finite automaton and test them. It is designed to be easy to read and understand.

- [finite-automaton](#finite-automaton)
	- [1. Usage](#1-usage)
	- [2. How to use the language](#2-how-to-use-the-language)
		- [2.1. Comments](#21-comments)
		- [2.2. Starting state](#22-starting-state)
		- [2.3. Events](#23-events)
		- [2.4. Single line test cases](#24-single-line-test-cases)
		- [2.5. Multi test cases](#25-multi-test-cases)
	- [3. File structure](#3-file-structure)
	- [4. How to pronounce lines](#4-how-to-pronounce-lines)
		- [4.1. Starting state](#41-starting-state)
		- [4.2. Events](#42-events)
		- [4.3. Single line test cases](#43-single-line-test-cases)
		- [4.4. Multi test cases](#44-multi-test-cases)
		- [4.5. Exemple](#45-exemple)
	- [5. Examples](#5-examples)
		- [5.1. 5.1 evenA](#51-51-evena)
		- [5.2. coffee](#52-coffee)

## 1. Usage
```
usage: finite-automaton.py [OPTIONS...] [FILE]
```
|Argument|Description|
|:---:|:---:|
| --dot `file` | dump the automaton in graphviz format into `file`. This doesn't check if the bot is valid before dumping allowing to use it as a debugger|
| -s | Display the substeps of the automaton when running it. This is usefull to debug the automaton and see what is happening.|
| -t `tests` | Run the test cases given by the `test` argument. It must be a list of test case separated by a `,`.|



## 2. How to use the language
### 2.1. Comments
In this language anything that is after a `#` is considered a comment and will be ignored by the parser.

### 2.2. Starting state
The starting state is usualy the first line of the file (see [File structure](#2-file-structure)) and it define the first state of the automaton after the creation.
It is defined as follow:
```
-> state_name
```
It can be only once in the file, if there is more than one or not any, it will cause an error.

### 2.3. Events
An event is a line that define a transition from a state to another on a specific event.
It is defined as follow:
```
base_state_name : event_name -> next_state_name
```
It can be as many as you whant but if you try to define non deterministic automaton, it will take the last instance of the event.

**Example:**
```
a:1->b
a:1->c
```
Will result in a automaton that will go to the state `c` when the event `1` is triggered from the state `a`. It will ignore the first line.

**Note:** There is a special event called `_` (Wildcard event) that will be triggered on any event. It will override any other event that is defined on the same state. This event will redirect the current state to the next state defined in the line and trigger the event that was supposed to be triggered.

**Example:**
```
a:1->a
a:2->b
b:_->a
```
Will result in a automaton that will go to the state `a` when the event `1` is triggered from the state `a` and will go to the state `b` when the event `2` is triggered from the state `a`. When the event `2` or the event `1` is triggered from the state `b`, it will go to the state `a` and trigger the event `2` or `1` again.

### 2.4. Single line test cases
A single line test case is a line that will test the automaton with a specific list of events and will check if the automaton is in the expected state at the end of the test.

**Note:** The base state of the test case is the state of the automaton after the creation and it will be reset to this state after the test.

It is defined as follow:
```
:event1,event2,event3,...,eventN -> expected_state
```
It can be as many as you whant.
**Note:** If you use a non existing expected state, the test will always fail. And if you use a non existing event, it will cause an error at runtime, there is no compile time check for this.

### 2.5. Multi test cases
A multi test case is a test that allow to keep the state of the automaton between each test. It is useful to test a sequence of events more precisely.

**Note:** This is also the only way to test the wildcard event (`_`) properly.

It is defined as follow:
```
:event1,event2,event3,...,eventN -> expected_state
|event1,event2,event3,...,eventN -> expected_state
|...
```
It can be as many as you whant.

## 3. File structure
Even if you can put lines in any order, it is recommended to folow the structure below to make it easier to read and understand.
The recommended structure is as follows:
- The starting state of the automaton
- The events that the automaton can handle sorted by starting state (all event that start from the same state should be together)
- The single line test cases
- The multi line test cases

## 4. How to pronounce lines
The language is designed to be easy to read and understand. so the lines are meant to be pronounced in a way that allow anyone to understand what is happening.

### 4.1. Starting state
This line is meant to be pronounced as follow:
```
The automaton start in the state <state_name>
```

### 4.2. Events
This line is meant to be pronounced as follow:
```
When the event <event_name> is triggered from the state <base_state_name>, the automaton go to the state <next_state_name>
```

### 4.3. Single line test cases
This line is meant to be pronounced as follow:
```
When the automaton receive the events <event1>, <event2>, <event3>, ..., <eventN>, it should be in the state <expected_state>
```

### 4.4. Multi test cases
This line is meant to be pronounced as follow:
```
When the automaton receive the events <event1>, <event2>, <event3>, ..., <eventN>, it should be in the state <expected_state> from there when it receive the events <event1>, <event2>, <event3>, ..., <eventN> it should be in the state <expected_state>
```

### 4.5. Exemple
```
-> a
a:1->b
a:2->c
b:1->b
b:2->c
c:1->b
c:2->c

:2,2 -> c
:2,1->b
|2->c
```
This file is meant to be pronounced as follow:
```
The automaton start in the state a
When the event 1 is triggered from the state a, the automaton go to the state b
When the event 2 is triggered from the state a, the automaton go to the state c
When the event 1 is triggered from the state b, the automaton go to the state b
When the event 2 is triggered from the state b, the automaton go to the state c
When the event 1 is triggered from the state c, the automaton go to the state b
When the event 2 is triggered from the state c, the automaton go to the state c

When the automaton receive the events 1, 2, 1, 2, it should be in the state c
When the automaton receive the events 2, 1, it should be in the state b from there when it receive the events 2 it should be in the state c
```

## 5. Examples
### 5.1. 5.1 evenA
This automaton will check if the number of `a` is even in a given string.

**Exemples:**
- "a" -> false
- "aa" -> true
- "abaa" -> false
- "abaaa" -> true
- "abbab" -> true

### 5.2. coffee
This automaton is a sort of dumb coffee machine. It will accept payment with coins of 5, 10 or 20 cents. It will give the coffee when the payment is more than 25 cents wihout giving change.

**Exemples:**
- 20,20 -> coffee
- 20,5 -> coffee
- 10,5 -> 15 (Insufficient payment)
- 5,5 -> 10 (Insufficient payment)