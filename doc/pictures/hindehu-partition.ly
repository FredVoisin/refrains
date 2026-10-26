\version "2.24.0"
\header { title = "Hìndèhú (un quart de ton plus bas)" tagline = ##f }
\score {
  {
    \cadenzaOn
    r8 e'8~ e'16 d''4~ d''8 r4 r16 e'8~ e'16 d''8~ d''16 r16 b'4 \bar ""
    r8 e'8~ e'16 d''4~ d''8 r4 r16 fis'8~ fis'16 r16 d''4~ d''8 r4 \bar ""
    fis'8~ fis'16 r16 d''8~ d''16 a'16 b'4~ b'16 r16 fis'8~ fis'16 r16 \bar ""
    d''4~ d''16 r4 r16 b'4 d''4~ d''8 r4 a'8~ a'16 r16 d''8~ d''16 \bar ""
    b'2~ b'8 d''4~ d''8 r4 r16 e'4 d''4~ d''16 r8 r16 e'4 d''8~ d''16 \bar ""
    r16 b'2~ b'8 d''4~ d''8 r4 fis'8~ fis'16 r16 d''4~ d''16 r4 r16 \bar ""
    fis'8~ fis'16 r16 d''8~ d''16 b'4~ b'8 r16 fis'8~ fis'16 r16 d''4~ d''8 \bar ""
    r8 e'16 r16 b'4 d''4~ d''8 r4 a'8~ a'16 r16 \bar ""
    d''8~ d''16 b'2~ b'8 d''4~ d''8 r8 \bar ""
  }
  \layout { \context { \Staff \accidentalStyle forget \omit TimeSignature } }
}
