#include <stdlib.h>
#include "Cpuinfo.hpp"

Cpuinfo::Cpuinfo() {
  mach_msg_type_number_t count;
  host_cpu_load_info_data_t cpuinfo;
  processor_info_array_t coreinfo;
  host_processor_info(mach_host_self(),
                      PROCESSOR_CPU_LOAD_INFO,
                      &this->core_count,
                      &coreinfo,
                      &count
                      );
  cores = (coreinfo_t *)malloc(sizeof(coreinfo_t) * this->core_count);
}

Cpuinfo::~Cpuinfo() {
  free(cores);
}

double Cpuinfo::getHostUsage() {
  return host.usage;
}

double Cpuinfo::getCoreUsageAt(unsigned int index) {
  return cores[index].usage;
}

unsigned int Cpuinfo::getCoreCount() {
  return this->core_count;
}

void Cpuinfo::setMultiCoreEnabled(bool enabled) {
  this->multiCoreEnabled = enabled;
}

void Cpuinfo::update() {
  mach_msg_type_number_t count;
  unsigned int core_count;  
  host_cpu_load_info_data_t hostinfo;
  processor_cpu_load_info_t coreinfo;
  natural_t user, system, idle, nice;
  double used, total;

  if(this->multiCoreEnabled) {
    // cores
    host_processor_info(mach_host_self(),
                        PROCESSOR_CPU_LOAD_INFO,
                        &core_count,
                        (processor_info_array_t *)&coreinfo,
                        &count
                        );
    for (unsigned int i = 0; i < this->core_count; i++) {
      user = coreinfo[i].cpu_ticks[CPU_STATE_USER] - cores[i].cpu_ticks[CPU_STATE_USER];
      system = coreinfo[i].cpu_ticks[CPU_STATE_SYSTEM] - cores[i].cpu_ticks[CPU_STATE_SYSTEM];
      idle = coreinfo[i].cpu_ticks[CPU_STATE_IDLE] - cores[i].cpu_ticks[CPU_STATE_IDLE];
      nice = coreinfo[i].cpu_ticks[CPU_STATE_NICE] - cores[i].cpu_ticks[CPU_STATE_NICE];
      used = user + system + nice;
      total = system + user + idle + nice;
      cores[i].usage = used / total;
      cores[i].cpu_ticks[CPU_STATE_USER] = coreinfo[i].cpu_ticks[CPU_STATE_USER];
      cores[i].cpu_ticks[CPU_STATE_SYSTEM] = coreinfo[i].cpu_ticks[CPU_STATE_SYSTEM];
      cores[i].cpu_ticks[CPU_STATE_IDLE] = coreinfo[i].cpu_ticks[CPU_STATE_IDLE];
      cores[i].cpu_ticks[CPU_STATE_NICE] = coreinfo[i].cpu_ticks[CPU_STATE_NICE];
    }
  }
  else {
    //host
    host_statistics(mach_host_self(),
                    HOST_CPU_LOAD_INFO,
                    (host_info_t)&hostinfo,
                    &count
                    );
    
    user = hostinfo.cpu_ticks[CPU_STATE_USER] - host.cpu_ticks[CPU_STATE_USER];
    system = hostinfo.cpu_ticks[CPU_STATE_SYSTEM] - host.cpu_ticks[CPU_STATE_SYSTEM];
    idle = hostinfo.cpu_ticks[CPU_STATE_IDLE] - host.cpu_ticks[CPU_STATE_IDLE];
    nice = hostinfo.cpu_ticks[CPU_STATE_NICE] - host.cpu_ticks[CPU_STATE_NICE];
    used = user + system + nice;
    total = system + user + idle + nice;
    host.usage = used / total;
    host.cpu_ticks[CPU_STATE_USER] = hostinfo.cpu_ticks[CPU_STATE_USER];
    host.cpu_ticks[CPU_STATE_SYSTEM] = hostinfo.cpu_ticks[CPU_STATE_SYSTEM];
    host.cpu_ticks[CPU_STATE_IDLE] = hostinfo.cpu_ticks[CPU_STATE_IDLE];
    host.cpu_ticks[CPU_STATE_NICE] = hostinfo.cpu_ticks[CPU_STATE_NICE];
  }
}
