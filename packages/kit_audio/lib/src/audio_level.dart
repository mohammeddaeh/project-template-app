/// An input level in dBFS (`-160` silence … `0` full scale) as `0`–`1`.
///
/// Speech sits between about −45 and −10 dBFS; the floor at −50 keeps room
/// noise near zero and lets a normal voice fill most of the bar.
double levelOfDbfs(double dbfs) {
  const floor = -50.0;
  if (dbfs.isNaN || dbfs <= floor) return 0;
  if (dbfs >= 0) return 1;
  return (dbfs - floor) / -floor;
}
