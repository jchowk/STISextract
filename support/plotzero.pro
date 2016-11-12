pro plotzero, XXX=xtrue

xxxxxxxxxxxxa = findgen(1000)*2.e3-1.e6
yyyyyyyyyyyya = replicate(0.000000e-12, 1000)

IF keyword_set(xtrue) THEN $
 oplot,yyyyyyyyyyyya, xxxxxxxxxxxxa,linestyle=1, nsum=1 $
ELSE $
 oplot,xxxxxxxxxxxxa,yyyyyyyyyyyya,linestyle=1, nsum=1

end
