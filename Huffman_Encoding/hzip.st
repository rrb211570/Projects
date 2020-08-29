#!/afs/cats.ucsc.edu/courses/cse112-wm/usr/smalltalk/bin/gst -f
"$Id: hzip.st,v 1.1 2020-02-15 13:23:59-08 - - $"

"Parse command line arguments"

nl := Character nl.

FileStream extend [
   nl := Character nl.
   catFile [
      |count|
      count := 0.
      [self atEnd not] whileTrue: [
         |padded|
         count := count + 1.
         padded := count printPaddedWith: Character space to: 6.
         stdout << padded << ': ' << self nextLine << nl.
      ]
   ]
].

Character extend [
   isGraph [
      ^ (Character space < self) & (self <= $~)
   ]
   visible [
      self isGraph ifTrue: [^ '$', self asString]
                   ifFalse: [^ self asInteger printStringRadix: 16]
   ]
]

Object subclass: BitStream [
   |bitIndex byte myStream|
   BitStream class >> new: fileStream [
      |result|
      result := super new.
      result init: fileStream.
      ^result
   ]
   init: fileStream [
      myStream := fileStream.
      bitIndex := 1.
   ]
   nextBit [
      bitIndex = 1 ifTrue: [
         byte := myStream next.
         bitIndex := 9.
      ].
      bitIndex := bitIndex - 1.
      ^byte value bitAt: bitIndex
   ]
   atEnd [
      ^bitIndex = 1 and: [myStream atEnd]
   ]
   currByte [
      ^byte
   ]
]

Object subclass: OutBits [
   |bitIndex currentByte myStream|
   bitIndex [^bitIndex]
   OutBits class >> new [
      self shouldNotImplement.
   ]
   OutBits class >> new: fileStream [
      |result|
      result := super new.
      result init: fileStream.
      ^result
   ]
   clearByte [
      bitIndex := 8.
      currentByte := 0.
   ]
   init: fileStream [
      myStream := fileStream.
      self clearByte.
   ]
   flushByte [
      bitIndex = 8 ifFalse: [
         myStream nextPutByte: currentByte.
         self clearByte.
      ]
   ]
   writeBit: bit [
      currentByte := currentByte bitAt: bitIndex put: bit.
      bitIndex := bitIndex - 1.
      bitIndex = 0 ifTrue: [self flushByte].
   ]
]

writeBitArray := [:outfile :lookup|
   |outBytes|
   outBytes := OutBits new: outfile.
   "stdout << 'writing: '."
   1 to: (lookup size) do: [:c|
      (lookup at: c) = $0 ifTrue: [
         outBytes writeBit: 0.
         "stdout << '0'."
      ].
      (lookup at: c) = $1 ifTrue: [
         outBytes writeBit: 1.
         "stdout << '1'."
      ].
   ].
   outBytes flushByte.
   "stdout << nl."
].

Object subclass: Leaf [
   |char count|
   char [ ^ char ]
   count [ ^ count ]

   Leaf class >> new [
      self shouldNotImplement
   ]

   Leaf class >> new: aChar count: aCount [
      |result|
      result := super new.
      result setChar: aChar andCount: aCount.
      ^result
   ]

   setChar: aChar andCount: aCount [
      char := aChar.
      count := aCount.
   ]

   <= other [
      ^ (count < other count)
      | ((count = other count) & (char <= other char))
   ]

   printBase: aStream [
      ^ aStream << self class << '(' << char << ',' << count
   ]

   printOn: aStream [
      (self printBase: aStream) << ')'.
   ]

   depthFirst: visitor prefix: string [
      visitor value: char value: string.
   ]

   postOrderTraversal [
      |x|
      x := '0'.
      char asInteger = 256 ifTrue: [
         x := x,'000000001'.
      ].
      char asInteger = 0 ifTrue: [
         x := x,'000000000'.
      ].
      (char asInteger < 256) & (char asInteger > 0) ifTrue: [
         x := x, ((char asInteger printPaddedWith: $0 to: 8
                                         base: 2) asString).
      ].
      ^ x.
   ]

   isLeaf [^1]
].

Leaf subclass: Tree [
   |left right|
   left[ ^ left ]
   right[ ^ right ]
   Tree class >> new: aChar count: aCount [
      self shouldNotImplement
   ]

   Tree class >> new: aChar count: aCount left: aLeft right: aRight [
      |result|
      result := super new: aChar count: aCount.
      result setLeft: aLeft andRight: aRight.
      ^ result
   ]

   setLeft: aLeft andRight: aRight [
      left := aLeft.
      right := aRight.
   ]

   printOn: aStream [
      (self printBase: aStream) << ',' << left << ',' << right << ')'.
   ]

   depthFirst: visitor prefix: string [
      left depthFirst: visitor prefix: string, '0'.
      right depthFirst: visitor prefix: string, '1'.
   ]

   postOrderTraversal [
      ^(left postOrderTraversal,
       right postOrderTraversal,
       '1').
   ]

   isLeaf [^0]
].

(Smalltalk arguments size < 2) |
(Smalltalk arguments size > 3) ifTrue: [
   stdout << 'Error: Correct format is ./hzip.st [flag] [input]'
          << ' [optional output]' << nl.
] ifFalse: [
   option := 4.
   1 to: 2 do: [:index |
       filename := (Smalltalk arguments at: index).
       index = 1 "--------------------------------flag-----------"
       ifTrue: [
          filename asString = '-t' ifTrue: [
             option := 0.
          ].
          filename asString = '-c' ifTrue: [
             option := 1.
          ].
          filename asString = '-u' ifTrue: [
             option := 2.
          ].
       ].
       index = 2  "--------------------------------input file------"
       ifTrue: [
          option < 2 ifTrue: [
          filename = '-'
             ifTrue: [stdin catFile]
             ifFalse: [
                [
                   |infile freqTable priorityQueue left right tree
                    outBytes outtf count2 outBin|
                   infile := FileStream open: filename
                                        mode: FileStream read.
                   freqTable := Array new: 257.
                   priorityQueue := SortedCollection new.
                   1 to: 257 do: [:index |
                      freqTable at: index put: 0.
                   ].
                   freqTable at: 256 put: 1.

                   stdinBits := BitStream new: infile.
                   count := 0.
                   [stdinBits atEnd] whileFalse: [ "---populate
                                                      freqTable--"
                      stdinBits nextBit.
                      count := count + 1.
                      count = 8 ifTrue: [
                         stdinBits currByte asInteger = 0 ifTrue: [
                            freqTable at: 257 put: 1 + (freqTable at:
                                                                257).
                         ] ifFalse: [
                            freqTable at: stdinBits currByte asInteger
                                  put: 1 + (freqTable at: stdinBits
                                       currByte asInteger).
                         ].
                         count := 0.
                      ].
                   ].
                   infile close.
                   "--------------populate priorityQueue------------"
                   (freqTable at: 257) = 0 ifFalse: [
                      a := Leaf new: Character nul
                             count: (freqTable at: 257).
                      priorityQueue add: a.
                   ].
                   1 to: 256 do: [:index |
                      (freqTable at: index) = 0 ifFalse: [
                         a := Leaf new: index asCharacter
                                 count: (freqTable at: index).
                         priorityQueue add: a.
                      ]
                   ].
                   [priorityQueue isEmpty] whileFalse: [
                      priorityQueue sortBlock: [:a :b |
                         a count = b count ifTrue: [
                            a char asInteger > b char asInteger
                         ] ifFalse: [
                            a count > b count
                         ]
                      ].
                      left := priorityQueue removeLast.
                      (priorityQueue isEmpty) ifFalse: [
                         right := priorityQueue removeLast.
                         tree := Tree new: (left char)
                                    count: ((left count) +
                                           (right count))
                                     left: left right: right.
                         priorityQueue add: tree.
                      ].
                   ].
                   encodeTable := Array new: 257.
                   "stdout << nl << 'Before visiting tree' << nl."
                   left depthFirst: [:char :string |
                      "stdout << '[' << char << ']=' << string << nl."
                      char asInteger = 0 ifFalse: [
                         encodeTable at: (char asInteger) put: string.
                      ] ifTrue: [
                         encodeTable at: 257 put: string.
                      ].

                   ] prefix: ''.

                   option = 0 ifTrue: [ "print encoding table"
                      (encodeTable at: 257) = nil ifFalse: [
                         stdout << ' x0  '.
                         Transcript show: ((freqTable at: 257)
                         printPaddedWith: Character space to: 5
                                                      base: 10).
                         stdout << '  '
                                << (encodeTable at: 257)
                                <<  nl.
                      ].
                      (1 to: 256) do: [:index |
                         (encodeTable at: index) = nil ifFalse: [
                            index <= 32 ifTrue: [
                               stdout << ' x'.
                               index printOn: Transcript base: 16.
                               index <= 15 ifTrue: [ stdout << ' '].
                               stdout << ' '.
                               Transcript show: ((freqTable at: index
                                                          asInteger)
                               printPaddedWith: Character space to: 5
                                                            base: 10).
                               stdout << '  '
                                      << (encodeTable at: index)
                                      <<  nl.
                            ].
                            index > 32 ifTrue: [
                               index = 256 ifTrue: [
                                  stdout << ' EOF '.
                                  Transcript show: ((freqTable at: index
                                                              asInteger)
                                  printPaddedWith: Character space to: 5
                                                             base: 10).
                                  stdout << '  '
                                       << (encodeTable at: index) << nl.
                               ] ifFalse: [
                                  stdout << ' ' << index asCharacter
                                         << '   '.
                                  Transcript show: ((freqTable at: index
                                                              asInteger)
                                  printPaddedWith: Character space to: 5
                                                              base: 10).
                                  stdout << '  '
                                       << (encodeTable at: index) << nl.
                               ].
                            ]
                         ]
                      ]
                   ].
                   outFile := stdout.
                   Smalltalk arguments size = 3 ifTrue: [
                      outFile := (Smalltalk arguments at: 3).
                   ].
                   option = 1 ifTrue: [ "Compress"
                      ans := left postOrderTraversal,'1'.

                      infile := FileStream open: filename
                                           mode: FileStream read.
                      outFile = stdout ifFalse: [
                         outtf := FileStream open: outFile
                                           mode: FileStream write.
                      ] ifTrue: [
                         outtf := outFile.
                      ].

                      stdinBits := BitStream new: infile.
                      count2 := 0.
                      outBytes := OutBits new: outtf.
                      outBin := ans.
                      [stdinBits atEnd] whileFalse: [
                         stdinBits nextBit.
                         count2 := count2 + 1.
                         count2 = 8 ifTrue: [
                            stdinBits currByte asInteger = 0 ifTrue: [
                               |st|
                               st := encodeTable at: 257.
                               ret := ''.
                               1 to: (st size) do: [:c|
                                  (st at: c) = $0 ifTrue: [
                                     ret := ret,'0'.
                                  ].
                                  (st at: c) = $1 ifTrue: [
                                     ret := ret,'1'.
                                  ].
                               ].
                               outBin := outBin, ret.
                            ] ifFalse: [
                               |st ch|
                               ch := stdinBits currByte value.
                               st := encodeTable at: ch.
                               ret := ''.

                               1 to: (st size) do: [:c|
                                  (st at: c) = $0 ifTrue: [
                                     ret := ret,'0'.
                                  ].
                                  (st at: c) = $1 ifTrue: [
                                     ret := ret,'1'.
                                  ].
                               ].
                               outBin := outBin, ret.
                            ].
                            count2 := 0.
                        ].

                      ].
                      st := encodeTable at: 256.
                      ret := ''.
                      1 to: (st size) do: [:c|
                        (st at: c) = $0 ifTrue: [
                           ret := ret,'0'.
                        ].
                        (st at: c) = $1 ifTrue: [
                           ret := ret,'1'.
                        ].
                      ].
                      outBin := outBin, ret.
                      writeBitArray value: outtf value: outBin.
                      infile close.
                      outtf = stdout ifFalse: [
                         outtf close.
                      ]
                   ].
                ] on: SystemExceptions.FileError do: [:signal |
                   |errno|
                   errno := File errno.
                   stdout flush.
                   stderr << '    ' << execname << ': ' << filename
                          << ': ' << signal messageText << nl << nl.
                   stderr flush.
                ]
             ].
          ].
          option = 2 ifTrue: [ "decompress"
          "[]"[
             |infile priorityQueue stdinBits rootPtr ptr ch
             left right tree outBytes2 outtf2 outFile2 outBin2|
             infile := FileStream open: filename
                                  mode: FileStream read.
             priorityQueue := OrderedCollection new.
             stdinBits := BitStream new: infile.
             count := 0.
             constructingTree := 0.
             outFile2 := stdout.
             Smalltalk arguments size = 3 ifTrue: [
                outFile2 := (Smalltalk arguments at: 3).
             ].
             outFile2 = stdout ifFalse: [
                outtf2 := FileStream open: outFile2
                                  mode: FileStream write.
             ] ifTrue: [
                outtf2 := outFile2.
             ].


             [stdinBits atEnd] whileFalse: [
                currBit := stdinBits nextBit.
                constructingTree = 0 ifTrue: [ "reconstructing TREE"
                   (currBit asInteger) = 0 ifTrue: [
                      fun := 0.
                      [count < 8] whileTrue: [
                         z := stdinBits nextBit.
                         fun := fun + (z*(2 raisedTo: (7-count))).
                         count := count  + 1.
                      ].
                      count := 0.
                      fun = 0 ifTrue: [
                       stdinBits nextBit = 0 ifTrue: [ "0"
                          a := Leaf new: Character nul count: 1.
                          priorityQueue add: a.
                       ] ifFalse: [            "EOF"
                          a := Leaf new: Character eof count: 1.
                          priorityQueue add: a.
                       ].
                      ] ifFalse: [   "normal ascii character"
                      a := Leaf new: (fun asCharacter)
                             count: 1.
                      priorityQueue add: a.
                      ].
                   ] ifFalse: [
                      right := priorityQueue removeLast.
                      priorityQueue isEmpty ifTrue: [
                         constructingTree := 1.
                         right isLeaf = 1 ifTrue: [
                            constructingTree := 2.
                         ].
                         rootPtr := right.
                         ptr := rootPtr.
                         currBit := stdinBits nextBit.
                      ] ifFalse: [
                         left := priorityQueue removeLast.
                         tree := Tree new: (left char)
                                     count: ((left count) +
                                            (right count))
                                     left: left right: right.
                         priorityQueue add: tree.
                      ]
                   ]
                ].
                constructingTree = 1 ifTrue: [ "parsing"
                   "traverse tree"
                   |flag exitFlag|
                   flag := 0.
                   exitFlag := 0.
                   ptr isLeaf = 1 ifTrue: [
                      ch := ptr char.
                      ch asInteger = 256 ifFalse: [
                         ch asInteger < 128 ifTrue: [
                            pl := ch asString asByteArray.
                            outtf2 nextPutByte: (pl at: 1).
                         ] ifFalse: [
                            outtf2 nextPutByte: (ch asInteger).
                         ].
                         ptr := rootPtr.
                      ]
                   ].
                   currBit = 0 ifTrue: [
                      ptr := ptr left.
                      ptr isLeaf = 1 ifTrue: [
                         ch := ptr char.
                         ch asInteger = 256  ifFalse: [
                            ch asInteger < 128 ifTrue: [
                               pl := ch asString asByteArray.
                               outtf2 nextPutByte: (pl at: 1).
                            ] ifFalse: [
                               outtf2 nextPutByte: (ch asInteger).
                            ].
                            ptr := rootPtr.
                         ]
                      ]
                   ] ifFalse: [
                      ptr := ptr right.
                      ptr isLeaf = 1 ifTrue: [
                         ch := ptr char.
                         ch asInteger = 256 ifFalse: [
                            ch asInteger < 128 ifTrue: [
                               pl := ch asString asByteArray.
                               outtf2 nextPutByte: (pl at: 1).
                            ] ifFalse: [
                               outtf2 nextPutByte: (ch asInteger).
                            ].
                            ptr := rootPtr.
                         ]
                      ]
                   ]
                ].
             ].

             outtf2 = stdout ifFalse: [
                outtf2 close.
             ].
             infile close.
          ] on: SystemExceptions.FileError do: [:signal |
               |errno|
             errno := File errno.
             stdout flush.
             stderr << '    ' << execname << ': ' << filename << ': '
                    << signal messageText << nl << nl.
             stderr flush.
          ].].
       ].
   ].
].

"TEST: hzip.st foo bar baz"
