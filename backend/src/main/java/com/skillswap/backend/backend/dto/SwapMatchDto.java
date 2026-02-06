package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class SwapMatchDto {
    private Long matchId;
    private String status;
    private Long otherUserId;
    private String otherName;
    private String myWanted;
    private String myOffered;
    private String otherWanted;
    private String otherOffered;
    private Boolean acceptedByMe;
    private Boolean acceptedByOther;
    private Boolean doneByMe;
    private Boolean doneByOther;
    private Boolean canReview;
}
