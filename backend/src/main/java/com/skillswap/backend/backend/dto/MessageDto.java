package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class MessageDto {
    private String from;
    private String preview;
    private String time;
    private boolean unread;
}
