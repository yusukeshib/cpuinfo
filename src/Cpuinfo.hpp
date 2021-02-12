#ifndef Cpuinfo_hpp
#define Cpuinfo_hpp

#include <mach/host_info.h>
#include <mach/vm_map.h>
#include <mach/mach_host.h>
#include <mach/processor_info.h>
#include <stdio.h>

typedef struct _coreinfo_t {
  natural_t cpu_ticks[CPU_STATE_MAX];
  double usage;
} coreinfo_t;

class Cpuinfo
{
public:
  Cpuinfo();
  virtual ~Cpuinfo();
  void update();
  double getHostUsage();
  double getCoreUsageAt(unsigned int index);
  unsigned int getCoreCount();
  void setMultiCoreEnabled(bool enabled);
  
private:
  bool multiCoreEnabled;
  unsigned int core_count;
  coreinfo_t host;
  coreinfo_t *cores;
};

#endif /* Cpuinfo_hpp */
