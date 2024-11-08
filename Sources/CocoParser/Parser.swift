/*-------------------------------------------------------------------------
    Compiler Generator Coco/R,
    Copyright (c) 1990, 2004 Hanspeter Moessenboeck, University of Linz
    extended by M. Loeberbauer & A. Woess, Univ. of Linz
    with improvements by Pat Terry, Rhodes University
    Swift port by Michael Griebling, 2015-2017

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2, or (at your option) any
    later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    As an exception, it is allowed to write an extension of Coco/R that is
    used as a plugin in non-free software.

    If not otherwise stated, any source code generated by Coco/R (other than
    Coco/R itself) does not fall under the GNU General Public License.

    NOTE: The code below has been automatically generated from the
    Parser.frame, Scanner.frame and Coco.atg files.  DO NOT EDIT HERE.
-------------------------------------------------------------------------*/

import Foundation



public class Parser {
	public let _EOF = 0
	public let _ident = 1
	public let _number = 2
	public let _string = 3
	public let _badString = 4
	public let _char = 5
	public let _COMPILER = 6
	public let _IGNORECASE = 7
	public let _CHARACTERS = 8
	public let _TOKENS = 9
	public let _PRAGMAS = 10
	public let _COMMENTS = 11
	public let _FROM = 12
	public let _TO = 13
	public let _NESTED = 14
	public let _IGNORE = 15
	public let _PRODUCTIONS = 16
	public let _END = 19
	public let _ANY = 23
	public let _WEAK = 29
	public let _SYNC = 36
	public let _IF = 37
	public let _CONTEXT = 38
	public let maxT = 41
	public let _ddtSym = 42
	public let _optionSym = 43

	static let _T = true
	static let _x = false
	static let minErrDist = 2
	let minErrDist : Int = Parser.minErrDist

	public var scanner: Scanner
	public var errors: Errors

	public var t: Token             // last recognized token
	public var la: Token            // lookahead token
	var errDist = Parser.minErrDist

	let id = 0
	let str = 1
	
	public var trace: OutputStream? // other Coco objects referenced in this ATG
	public var tab = Tab()
	public var dfa: DFA?
	public var pgen: ParserGen?
	
	var genScanner = false
	var tokenString = ""            // used in declarations of literal tokens
	let noString = "-none-"         // used in declarations of literal tokens
	
	/*-------------------------------------------------------------------------*/
	
	


    public init(scanner: Scanner) {
        self.scanner = scanner
        errors = Errors()
        t = Token()
        la = t
    }
    
    func SynErr (_ n: Int) {
        if errDist >= minErrDist { errors.SynErr(la.line, col: la.col, n: n) }
        errDist = 0
    }
    
    public func SemErr (_ msg: String) {
        if errDist >= minErrDist { errors.SemErr(t.line, col: t.col, s: msg) }
        errDist = 0
    }

	func Get () {
		while true {
            t = la
            la = scanner.Scan()
            if la.kind <= maxT { errDist += 1; break }
				if la.kind == _ddtSym {
					tab.SetDDT(la.val) 
				}
				if la.kind == _optionSym {
					tab.SetOption(la.val) 
				}

			la = t
		}
	}
	
    func Expect (_ n: Int) {
        if la.kind == n { Get() } else { SynErr(n) }
    }
    
    func StartOf (_ s: Int) -> Bool {
        return set(s, la.kind)
    }
    
    func ExpectWeak (_ n: Int, _ follow: Int) {
        if la.kind == n {
			Get()
		} else {
            SynErr(n)
            while !StartOf(follow) { Get() }
        }
    }
    
    func WeakSeparator(_ n: Int, _ syFol: Int, _ repFol: Int) -> Bool {
        var kind = la.kind
        if kind == n { Get(); return true }
        else if StartOf(repFol) { return false }
        else {
            SynErr(n)
            while !(set(syFol, kind) || set(repFol, kind) || set(0, kind)) {
                Get()
                kind = la.kind
            }
            return StartOf(syFol)
        }
    }

	func Coco() {
		var sym: Symbol?; var g, g1, g2: Graph?; let gramName: String; var s = CharSet(); var beg, line: Int 
		if StartOf(1) {
			Get()
			beg = t.pos; line = t.line 
			while StartOf(1) {
				Get()
			}
			pgen!.usingPos = Position(beg, la.pos, 0, line) 
		}
		Expect(_COMPILER)
		genScanner = true
		tab.ignored = CharSet() 
		Expect(_ident)
		gramName = t.val
		beg = la.pos; line = la.line
		
		while StartOf(2) {
			Get()
		}
		tab.semDeclPos = Position(beg, la.pos, 0, line) 
		if la.kind == _IGNORECASE {
			Get()
			dfa!.ignoreCase = true 
		}
		if la.kind == _CHARACTERS {
			Get()
			while la.kind == _ident {
				SetDecl()
			}
		}
		if la.kind == _TOKENS {
			Get()
			while la.kind == _ident || la.kind == _string || la.kind == _char {
				TokenDecl(Node.t)
			}
		}
		if la.kind == _PRAGMAS {
			Get()
			while la.kind == _ident || la.kind == _string || la.kind == _char {
				TokenDecl(Node.pr)
			}
		}
		while la.kind == _COMMENTS {
			Get()
			var nested = false 
			Expect(_FROM)
			TokenExpr(&g1)
			Expect(_TO)
			TokenExpr(&g2)
			if la.kind == _NESTED {
				Get()
				nested = true 
			}
			dfa?.NewComment(g1!.l!, g2!.l!, nested) 
		}
		while la.kind == _IGNORE {
			Get()
			Set(&s)
			tab.ignored.Or(s) 
		}
		while !(la.kind == _EOF || la.kind == _PRODUCTIONS) { SynErr(42); Get() }
		Expect(_PRODUCTIONS)
		if genScanner { dfa?.MakeDeterministic() }
		tab.DeleteNodes()
		
		while la.kind == _ident {
			Get()
			sym = tab.FindSym(t.val)
			let undef = sym == nil
			if undef { sym = tab.NewSym(Node.nt, t.val, t.line) }
			else {
			   if sym!.typ == Node.nt {
			       if sym!.graph != nil { SemErr("name declared twice") }
			   } else { SemErr("this symbol kind not allowed on left side of production") }
			   sym!.line = t.line
			}
			let noAttrs = sym!.attrPos == nil
			sym!.attrPos = nil
			
			if la.kind == 24 /* "<" */ || la.kind == 26 /* "<." */ {
				AttrDecl(sym!)
			}
			if !undef {
			   if noAttrs != (sym!.attrPos == nil) {
			       SemErr("attribute mismatch between declaration and use of this symbol")
			   }
			}
			
			if la.kind == 39 /* "(." */ {
				SemText(&sym!.semPos)
			}
			ExpectWeak(17 /* "=" */, 3)
			Expression(&g)
			sym!.graph = g!.l
			tab.Finish(g!) 
			ExpectWeak(18 /* "." */, 4)
		}
		Expect(_END)
		Expect(_ident)
		if gramName != t.val {
		   SemErr("name does not match grammar name")
		}
		tab.gramSy = tab.FindSym(gramName)
		if tab.gramSy == nil {
		   SemErr("missing production for grammar name")
		} else {
		   sym = tab.gramSy
		   if sym!.attrPos != nil {
		       SemErr("grammar symbol must not have attributes")
		   }
		}
		tab.noSym = tab.NewSym(Node.t, "???", 0) // noSym gets highest number
		tab.SetupAnys()
		tab.RenumberPragmas()
		if tab.ddt[2] { tab.PrintNodes() }
		if errors.count == 0 {
		   print("checking")
		   tab.CompSymbolSets()
		   if tab.ddt[7] { tab.XRef() }
		   if tab.GrammarOk() {
		       print("parser", terminator: "")
		       pgen?.WriteParser()
		       if genScanner {
		           print(" + scanner", terminator: "")
		           dfa?.WriteScanner()
		           if tab.ddt[0] { dfa?.PrintStates() }
		       }
		       print(" generated")
		       if tab.ddt[8] { pgen?.WriteStatistics() }
		   }
		}
		if tab.ddt[6] { tab.PrintSymbolTable() } 
		Expect(18 /* "." */)
	}

	func SetDecl() {
		var s = CharSet() 
		Expect(_ident)
		let name = t.val
		let c = tab.FindCharClass(name)
		if c != nil { SemErr("name declared twice") }
		
		Expect(17 /* "=" */)
		Set(&s)
		if s.Elements() == 0 { SemErr("character set must not be empty") }
		_ = tab.NewCharClass(name, s) 
		Expect(18 /* "." */)
	}

	func TokenDecl(_ typ: Int) {
		var name = ""; var kind = 0; var sym: Symbol?; var g: Graph? 
		Sym(&name, &kind)
		sym = tab.FindSym(name)
		if sym != nil { SemErr("name declared twice") }
		else {
		   sym = tab.NewSym(typ, name, t.line)
		   sym!.tokenKind = Symbol.fixedToken
		}
		tokenString = ""
		
		while !(StartOf(5)) { SynErr(43); Get() }
		if la.kind == 17 /* "=" */ {
			Get()
			TokenExpr(&g)
			Expect(18 /* "." */)
			if kind == str { SemErr("a literal must not be declared with a structure") }
			tab.Finish(g!)
			if tokenString.isEmpty || tokenString == noString {
			   dfa?.ConvertToStates(g!.l!, sym!)
			} else { // TokenExpr is a single string
			   if tab.literals[tokenString] != nil {
			       SemErr("token string declared twice")
			   }
			   tab.literals[tokenString] = sym
			   dfa?.MatchLiteral(tokenString, sym!)
			}
			
		} else if StartOf(6) {
			if kind == id { genScanner = false }
			else { dfa?.MatchLiteral(sym!.name, sym!) }
			
		} else { SynErr(44) }
		if la.kind == 39 /* "(." */ {
			SemText(&sym!.semPos)
			if typ != Node.pr { SemErr("semantic action not allowed here") } 
		}
	}

	func TokenExpr(_ g: inout Graph?) {
		var g2: Graph? 
		TokenTerm(&g)
		var first = true 
		while WeakSeparator(28 /* "|" */,7,8) {
			TokenTerm(&g2)
			if first { tab.MakeFirstAlt(g!); first = false }
			         tab.MakeAlternative(g!, g2!) 
		}
	}

	func Set(_ s: inout CharSet) {
		var s2 = CharSet() 
		SimSet(&s)
		while la.kind == 20 /* "+" */ || la.kind == 21 /* "-" */ {
			if la.kind == 20 /* "+" */ {
				Get()
				SimSet(&s2)
				s.Or(s2) 
			} else {
				Get()
				SimSet(&s2)
				s.Subtract(s2) 
			}
		}
	}

	func AttrDecl(_ sym: Symbol) {
		if la.kind == 24 /* "<" */ {
			Get()
			let beg = la.pos; let col = la.col; let line = la.line 
			while StartOf(9) {
				if StartOf(10) {
					Get()
				} else {
					Get()
					SemErr("bad string in attributes") 
				}
			}
			Expect(25 /* ">" */)
			if t.pos > beg {
			   sym.attrPos = Position(beg, t.pos, col, line)
			} 
		} else if la.kind == 26 /* "<." */ {
			Get()
			let beg = la.pos; let col = la.col; let line = la.line 
			while StartOf(11) {
				if StartOf(12) {
					Get()
				} else {
					Get()
					SemErr("bad string in attributes") 
				}
			}
			Expect(27 /* ".>" */)
			if t.pos > beg {
			    sym.attrPos = Position(beg, t.pos, col, line);
			} 
		} else { SynErr(45) }
	}

	func SemText(_ pos: inout Position?) {
		Expect(39 /* "(." */)
		let beg = la.pos; let col = la.col; let line = la.line 
		while StartOf(13) {
			if StartOf(14) {
				Get()
			} else if la.kind == _badString {
				Get()
				SemErr("bad string in semantic action") 
			} else {
				Get()
				SemErr("missing end of previous semantic action") 
			}
		}
		Expect(40 /* ".)" */)
		pos = Position(beg, t.pos, col, line) 
	}

	func Expression(_ g: inout Graph?) {
		var g2: Graph? 
		Term(&g)
		var first = true 
		while WeakSeparator(28 /* "|" */,15,16) {
			Term(&g2)
			if first { tab.MakeFirstAlt(g!); first = false }
			tab.MakeAlternative(g!, g2!) 
		}
	}

	func SimSet(_ s: inout CharSet) {
		var n1 = 0; var n2 = 0 
		s = CharSet() 
		if la.kind == _ident {
			Get()
			let c = tab.FindCharClass(t.val)
			if c == nil { SemErr("undefined name") } else { s.Or(c!.set) }
			
		} else if la.kind == _string {
			Get()
			var name = t.val
			name = tab.Unescape(name.substring(1, name.count-2))
			for ch in name {
			if dfa!.ignoreCase { s.Set(ch.lowercased.unicodeValue) }
			else { s.Set(ch.unicodeValue) }
			} 
		} else if la.kind == _char {
			Char(&n1)
			s.Set(n1) 
			if la.kind == 22 /* ".." */ {
				Get()
				Char(&n2)
				for i in n1...n2 { s.Set(i) } 
			}
		} else if la.kind == _ANY {
			Get()
			s = CharSet(); s.Fill() 
		} else { SynErr(46) }
	}

	func Char(_ n: inout Int) {
		Expect(_char)
		var name = t.val; n = 0
		name = tab.Unescape(name.substring(1, name.count-2))
		if name.count == 1 { n = name[0].unicodeValue }
		else { SemErr("unacceptable character value") }
		if dfa!.ignoreCase && Character(n) >= "A" && Character(n) <= "Z" { n += 32 } 
	}

	func Sym(_ name: inout String, _ kind: inout Int) {
		name = "???"; kind = id 
		if la.kind == _ident {
			Get()
			kind = id; name = t.val 
		} else if la.kind == _string || la.kind == _char {
			if la.kind == _string {
				Get()
				name = t.val 
			} else {
				Get()
				name = "\"" + t.val.substring(1, t.val.count-2) + "\"" 
			}
			kind = str
			if dfa!.ignoreCase { name = name.lowercased() }
			if name.contains(" ") { SemErr("literal tokens must not contain blanks") } 
		} else { SynErr(47) }
	}

	func Term(_ g: inout Graph?) {
		var g2: Graph?; var rslv: Node? = nil
		g = nil 
		if StartOf(17) {
			if la.kind == _IF {
				rslv = tab.NewNode(Node.rslv, nil, la.line) 
				Resolver(&rslv!.pos)
				g = Graph(rslv) 
			}
			Factor(&g2)
			if rslv != nil { tab.MakeSequence(g!, g2!) }
			else { g = g2 }
			           
			while StartOf(18) {
				Factor(&g2)
				tab.MakeSequence(g!, g2!) 
			}
		} else if StartOf(19) {
			g = Graph(tab.NewNode(Node.eps, nil, 0)) 
		} else { SynErr(48) }
		if g == nil { // invalid start of Term
		   g = Graph(tab.NewNode(Node.eps, nil, 0))
		} 
	}

	func Resolver(_ pos: inout Position?) {
		Expect(_IF)
		Expect(30 /* "(" */)
		let beg = la.pos; let col = la.col; let line = la.line 
		Condition()
		pos = Position(beg, t.pos, col, line) 
	}

	func Factor(_ g: inout Graph?) {
		var name = ""; var kind = 0; var pos: Position?; var weak = false
		g = nil
		
		switch la.kind {
		case _ident, _string, _char, _WEAK: 
			if la.kind == _WEAK {
				Get()
				weak = true 
			}
			Sym(&name, &kind)
			var sym = tab.FindSym(name)
			if sym == nil && kind == str {
			   sym = tab.literals[name]
			}
			let undef = sym == nil
			if undef {
			   if kind == id {
			       sym = tab.NewSym(Node.nt, name, 0)  // forward nt
			   } else if genScanner {
			       sym = tab.NewSym(Node.t, name, t.line)
			       dfa?.MatchLiteral(sym!.name, sym!)
			   } else {  // undefined string in production
			       SemErr("undefined string in production")
			       sym = tab.eofSy  // dummy
			   }
			}
			var typ = sym!.typ
			if typ != Node.t && typ != Node.nt {
			   SemErr("this symbol kind is not allowed in a production");
			}
			if weak {
			   if typ == Node.t { typ = Node.wt }
			   else { SemErr("only terminals may be weak") }
			}
			let p = tab.NewNode(typ, sym, t.line)
			g = Graph(p) 
			if la.kind == 24 /* "<" */ || la.kind == 26 /* "<." */ {
				Attribs(p)
				if kind != id { SemErr("a literal must not have attributes") } 
			}
			if undef {
			   sym!.attrPos = p.pos  // dummy
			} else if (p.pos == nil) != (sym!.attrPos == nil) {
			   SemErr("attribute mismatch between declaration and use of this symbol")
			} 
		case 30 /* "(" */: 
			Get()
			Expression(&g)
			Expect(31 /* ")" */)
		case 32 /* "[" */: 
			Get()
			Expression(&g)
			Expect(33 /* "]" */)
			tab.MakeOption(g!) 
		case 34 /* "{" */: 
			Get()
			Expression(&g)
			Expect(35 /* "}" */)
			tab.MakeIteration(g!) 
		case 39 /* "(." */: 
			SemText(&pos)
			let p = tab.NewNode(Node.sem, nil, 0)
			p.pos = pos
			g = Graph(p) 
		case _ANY: 
			Get()
			let p = tab.NewNode(Node.any, nil, 0)  // p.set is set in tab.SetupAnys
			g = Graph(p) 
		case _SYNC: 
			Get()
			let p = tab.NewNode(Node.sync, nil, 0)
			g = Graph(p) 
		default: SynErr(49)
		}
		if g == nil { // invalid start of Factor
		   g = Graph(tab.NewNode(Node.eps, nil, 0))
		}
		
	}

	func Attribs(_ p: Node) {
		if la.kind == 24 /* "<" */ {
			Get()
			let beg = la.pos; let col = la.col; let line = la.line 
			while StartOf(9) {
				if StartOf(10) {
					Get()
				} else {
					Get()
					SemErr("bad string in attributes") 
				}
			}
			Expect(25 /* ">" */)
			if t.pos > beg { p.pos = Position(beg, t.pos, col, line) } 
		} else if la.kind == 26 /* "<." */ {
			Get()
			let beg = la.pos; let col = la.col; let line = la.line 
			while StartOf(11) {
				if StartOf(12) {
					Get()
				} else {
					Get()
					SemErr("bad string in attributes") 
				}
			}
			Expect(27 /* ".>" */)
			if t.pos > beg { p.pos = Position(beg, t.pos, col, line) } 
		} else { SynErr(50) }
	}

	func Condition() {
		while StartOf(20) {
			if la.kind == 30 /* "(" */ {
				Get()
				Condition()
			} else {
				Get()
			}
		}
		Expect(31 /* ")" */)
	}

	func TokenTerm(_ g: inout Graph?) {
		var g2: Graph? 
		TokenFactor(&g)
		while StartOf(7) {
			TokenFactor(&g2)
			tab.MakeSequence(g!, g2!) 
		}
		if la.kind == _CONTEXT {
			Get()
			Expect(30 /* "(" */)
			TokenExpr(&g2)
			tab.SetContextTrans(g2!.l); dfa!.hasCtxMoves = true
			tab.MakeSequence(g!, g2!) 
			Expect(31 /* ")" */)
		}
	}

	func TokenFactor(_ g: inout Graph?) {
		var name = ""; var kind = 0 
		g = nil 
		if la.kind == _ident || la.kind == _string || la.kind == _char {
			Sym(&name, &kind)
			if kind == id {
			   var c = tab.FindCharClass(name)
			   if c == nil {
			       SemErr("undefined name")
			       c = tab.NewCharClass(name, CharSet())
			   }
			   let p = tab.NewNode(Node.clas, nil, 0); p.val = c!.n
			   g = Graph(p)
			   tokenString = noString
			} else { // str
			   g = tab.StrToGraph(name)
			   if tokenString.isEmpty { tokenString = name }
			   else { tokenString = noString }
			}  
		} else if la.kind == 30 /* "(" */ {
			Get()
			TokenExpr(&g)
			Expect(31 /* ")" */)
		} else if la.kind == 32 /* "[" */ {
			Get()
			TokenExpr(&g)
			Expect(33 /* "]" */)
			tab.MakeOption(g!); tokenString = noString 
		} else if la.kind == 34 /* "{" */ {
			Get()
			TokenExpr(&g)
			Expect(35 /* "}" */)
			tab.MakeIteration(g!); tokenString = noString 
		} else { SynErr(51) }
		if g == nil { // invalid start of TokenFactor
		   g = Graph(tab.NewNode(Node.eps, nil, 0))
		} 
	}



    public func Parse() {
        la = Token()
        la.val = ""
        Get()
		Coco()
		Expect(_EOF)

	}

    func set (_ x: Int, _ y: Int) -> Bool { return Parser._set[x][y] }
    static let _set: [[Bool]] = [
		[_T,_T,_x,_T, _x,_T,_x,_x, _x,_x,_T,_T, _x,_x,_x,_T, _T,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_x,_x],
		[_x,_T,_T,_T, _T,_T,_x,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x],
		[_x,_T,_T,_T, _T,_T,_T,_x, _x,_x,_x,_x, _T,_T,_T,_x, _x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x],
		[_T,_T,_x,_T, _x,_T,_x,_x, _x,_x,_T,_T, _x,_x,_x,_T, _T,_T,_T,_x, _x,_x,_x,_T, _x,_x,_x,_x, _T,_T,_T,_x, _T,_x,_T,_x, _T,_T,_x,_T, _x,_x,_x],
		[_T,_T,_x,_T, _x,_T,_x,_x, _x,_x,_T,_T, _x,_x,_x,_T, _T,_T,_x,_T, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_x,_x],
		[_T,_T,_x,_T, _x,_T,_x,_x, _x,_x,_T,_T, _x,_x,_x,_T, _T,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_x,_x],
		[_x,_T,_x,_T, _x,_T,_x,_x, _x,_x,_T,_T, _x,_x,_x,_T, _T,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_x,_x],
		[_x,_T,_x,_T, _x,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_T,_x, _T,_x,_T,_x, _x,_x,_x,_x, _x,_x,_x],
		[_x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_T,_T,_T, _T,_x,_T,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_T,_x,_T, _x,_x,_x,_x, _x,_x,_x],
		[_x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_x,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x],
		[_x,_T,_T,_T, _x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_x,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x],
		[_x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_x, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x],
		[_x,_T,_T,_T, _x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_x, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x],
		[_x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _x,_T,_x],
		[_x,_T,_T,_T, _x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_x, _x,_T,_x],
		[_x,_T,_x,_T, _x,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_T,_x, _x,_x,_x,_T, _x,_x,_x,_x, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x,_T, _x,_x,_x],
		[_x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_T,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_T,_x,_T, _x,_x,_x,_x, _x,_x,_x],
		[_x,_T,_x,_T, _x,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_x,_x,_x, _x,_T,_T,_x, _T,_x,_T,_x, _T,_T,_x,_T, _x,_x,_x],
		[_x,_T,_x,_T, _x,_T,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_T, _x,_x,_x,_x, _x,_T,_T,_x, _T,_x,_T,_x, _T,_x,_x,_T, _x,_x,_x],
		[_x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_x,_x, _x,_x,_T,_x, _x,_x,_x,_x, _x,_x,_x,_x, _T,_x,_x,_T, _x,_T,_x,_T, _x,_x,_x,_x, _x,_x,_x],
		[_x,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_T,_x, _T,_T,_T,_T, _T,_T,_T,_T, _T,_T,_x]

	]
} // end Parser


public class Errors {
    public var count = 0                                 // number of errors detected
    private let errorStream = Darwin.stderr              // error messages go to this stream
    public var errMsgFormat = "-- line %i col %i: %@"    // 0=line, 1=column, 2=text
    
    func Write(_ s: String) { fputs(s, errorStream) }
    func WriteLine(_ format: String, line: Int, col: Int, s: String) {
        let str = String(format: format, line, col, s)
        WriteLine(str)
    }
    func WriteLine(_ s: String) { Write(s + "\n") }
    
    public func SynErr (_ line: Int, col: Int, n: Int) {
        var s: String
        switch n {
		case 0: s = "EOF expected"
		case 1: s = "ident expected"
		case 2: s = "number expected"
		case 3: s = "string expected"
		case 4: s = "badString expected"
		case 5: s = "char expected"
		case 6: s = "\"COMPILER\" expected"
		case 7: s = "\"IGNORECASE\" expected"
		case 8: s = "\"CHARACTERS\" expected"
		case 9: s = "\"TOKENS\" expected"
		case 10: s = "\"PRAGMAS\" expected"
		case 11: s = "\"COMMENTS\" expected"
		case 12: s = "\"FROM\" expected"
		case 13: s = "\"TO\" expected"
		case 14: s = "\"NESTED\" expected"
		case 15: s = "\"IGNORE\" expected"
		case 16: s = "\"PRODUCTIONS\" expected"
		case 17: s = "\"=\" expected"
		case 18: s = "\".\" expected"
		case 19: s = "\"END\" expected"
		case 20: s = "\"+\" expected"
		case 21: s = "\"-\" expected"
		case 22: s = "\"..\" expected"
		case 23: s = "\"ANY\" expected"
		case 24: s = "\"<\" expected"
		case 25: s = "\">\" expected"
		case 26: s = "\"<.\" expected"
		case 27: s = "\".>\" expected"
		case 28: s = "\"|\" expected"
		case 29: s = "\"WEAK\" expected"
		case 30: s = "\"(\" expected"
		case 31: s = "\")\" expected"
		case 32: s = "\"[\" expected"
		case 33: s = "\"]\" expected"
		case 34: s = "\"{\" expected"
		case 35: s = "\"}\" expected"
		case 36: s = "\"SYNC\" expected"
		case 37: s = "\"IF\" expected"
		case 38: s = "\"CONTEXT\" expected"
		case 39: s = "\"(.\" expected"
		case 40: s = "\".)\" expected"
		case 41: s = "??? expected"
		case 42: s = "this symbol not expected in Coco"
		case 43: s = "this symbol not expected in TokenDecl"
		case 44: s = "invalid TokenDecl"
		case 45: s = "invalid AttrDecl"
		case 46: s = "invalid SimSet"
		case 47: s = "invalid Sym"
		case 48: s = "invalid Term"
		case 49: s = "invalid Factor"
		case 50: s = "invalid Attribs"
		case 51: s = "invalid TokenFactor"

        default: s = "error \(n)"
        }
        WriteLine(errMsgFormat, line: line, col: col, s: s)
        count += 1
	}

    public func SemErr (_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s);
        count += 1
    }
    
    public func SemErr (_ s: String) {
        WriteLine(s)
        count += 1
    }
    
    public func Warning (_ line: Int, col: Int, s: String) {
        WriteLine(errMsgFormat, line: line, col: col, s: s)
    }
    
    public func Warning(_ s: String) {
        WriteLine(s)
    }
} // Errors
