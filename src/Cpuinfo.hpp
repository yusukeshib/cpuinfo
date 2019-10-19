#ifndef Cpuinfo_hpp
#define Cpuinfo_hpp

#include <mach/host_info.h>
#include <mach/mach_host.h>
#include <mach/processor_info.h>
#include <stdio.h>

class Cpuinfo
{
public:
  Cpuinfo();
  void update();
  double getUsage();
  
private:
  host_cpu_load_info_data_t _prev;
  mach_port_t _hostport;
  double _usage;
};

#endif /* Cpuinfo_hpp */
