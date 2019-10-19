#include "Cpuinfo.hpp"

Cpuinfo::Cpuinfo() {
  _hostport = mach_host_self();
  mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
  host_statistics(_hostport, HOST_CPU_LOAD_INFO, (host_info_t)&_prev, &count);
}

double Cpuinfo::getUsage() {
  return _usage;
}

void Cpuinfo::update() {
  mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
  host_cpu_load_info_data_t cpuinfo;
  host_statistics(_hostport, HOST_CPU_LOAD_INFO, (host_info_t)&cpuinfo, &count);
  
  natural_t user, system, idle, nice;
  user = cpuinfo.cpu_ticks[CPU_STATE_USER] - _prev.cpu_ticks[CPU_STATE_USER];
  system = cpuinfo.cpu_ticks[CPU_STATE_SYSTEM] - _prev.cpu_ticks[CPU_STATE_SYSTEM];
  idle = cpuinfo.cpu_ticks[CPU_STATE_IDLE] - _prev.cpu_ticks[CPU_STATE_IDLE];
  nice = cpuinfo.cpu_ticks[CPU_STATE_NICE] - _prev.cpu_ticks[CPU_STATE_NICE];
  double used = user + system + nice;
  double total = system + user + idle + nice;
  
  _usage = used / total;
  _prev = cpuinfo;
}
