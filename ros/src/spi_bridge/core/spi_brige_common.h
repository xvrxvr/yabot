#pragma once

#include <stdint.h>

#include <ros/ros.h>

#include <deque>
#include <vector>
#include <thread>
#include <mutex>
#include <fstream>

constexpr int LOOP_RATE = 30; //processing frequency


// HW setup
constexpr size_t SPI_QUEUE_SIZE = 8192; // Size of inbound/outbound queue
constexpr size_t SPI_INT_QUEUE_SIZE = 6000; // Size of interrupt queue
