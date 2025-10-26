
import «20251023Facet».Extension

def hello := "world"

secretive x :=
  __REDACTED "hello" __ ++ " world"

secretive y := 412345 + (__REDACTED "whatever" __).length
