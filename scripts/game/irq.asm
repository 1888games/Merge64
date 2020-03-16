
IRQ: {

	.label IRQControlRegister1 = $dc0d
	.label IRQControlRegister2 = $dd0d

	.label MainIRQLine= 218

	IRQ_Rows:	.byte 46, 81, 121, 161, 201
	IRQ_Index:	.byte 0


	DontDrawYet:	.byte 0



	DisableCIA: {

		// prevent CIA interrupts now the kernal is banked out
		lda #$7f
		sta IRQControlRegister1
		sta IRQControlRegister2

		rts

	}


	SetupInterrupts: {

		sei 	// disable interrupt flag
		lda VIC.INTERRUPT_CONTROL
		ora #%00000001		// turn on raster interrupts
		sta VIC.INTERRUPT_CONTROL

		lda #<TopIRQ
		ldx #>TopIRQ
		ldy #0
		jsr SetNextInterrupt

		asl VIC.INTERRUPT_STATUS
		cli

		rts


	}



	SetNextInterrupt: {

		sta REGISTERS.RASTER_INTERRUPT_VECTOR
		stx REGISTERS.RASTER_INTERRUPT_VECTOR + 1
		sty VIC.RASTER_Y
		lda VIC.SCREEN_CONTROL
		and #%01111111		// don't use 255+
		sta VIC.SCREEN_CONTROL

		rts
	}



	SpriteIRQ: {

		:StoreState()

			
		SetDebugBorder(4)

		ldy IRQ_Index
		
		jsr BLOCK.DrawRow
		//jsr ENEMIES.GetNextIRQLine 

		inc IRQ_Index
		lda IRQ_Index
		cmp #5
		bcc StillDrawing

		jmp BackToMain

		StillDrawing:

		tay
		lda IRQ_Rows, y
		tay
		
		sty VIC.RASTER_Y
		lda VIC.SCREEN_CONTROL
		and #%01111111		// don't use 255+
		sta VIC.SCREEN_CONTROL


		jmp FinishInterrupt
 
		BackToMain:

			lda #<MainIRQ
			ldx #>MainIRQ
			ldy #MainIRQLine
			jsr SetNextInterrupt 

		FinishInterrupt:

			asl VIC.INTERRUPT_STATUS

			SetDebugBorder(0)
			:RestoreState()

			rti

	}

	SpriteRow2: {

		:StoreState()


		asl VIC.INTERRUPT_STATUS

		:RestoreState()

		rti

	}



	SetupMainIRQ:{


		lda #<MainIRQ
		ldx #>MainIRQ
		ldy #MainIRQLine
		jsr SetNextInterrupt 

		rts



	}
	



	TopIRQ: {


		:StoreState()

		
		ldy #2
		jsr INPUT.ReadJoystick

		lda MAIN.GameActive
		beq NoSprites


			lda #<SpriteIRQ
			ldx #>SpriteIRQ
			jsr SetNextInterrupt 
			jmp Finish

		NoSprites:


			ldy #MainIRQLine
			lda #<MainIRQ
			ldx #>MainIRQ
			jsr SetNextInterrupt 

		Finish:

		asl VIC.INTERRUPT_STATUS

		:RestoreState()

		rti


	}
	
	MainIRQ: {

		:StoreState()

		SetDebugBorder(2)
	
		lda #1
		sta MAIN.PerformFrameCodeFlag

	

		ldy #2
		jsr INPUT.ReadJoystick
		
		inc ZP_COUNTER

		lda MAIN.GameActive
		beq Paused

		GameActive:

			jsr sid.play
			jsr BLOCK.MoveBlocks
			jsr CONTROL.Update
			jmp Finish

		Paused:

		 lda MAIN.GameIsOver
		 beq Finish
		
		 lda MAIN.GameOverTimer
		 beq CheckFireButton

		 dec MAIN.GameOverTimer
		 jmp Finish

		 CheckFireButton:

		 	ldy #1
		 	lda INPUT.FIRE_UP_THIS_FRAME, y
		 	beq Finish

		Finish:

		//jsr SCORE.CheckScoreToAdd

		BackToSprite:

			lda #0
			sta IRQ_Index

			tay
			lda IRQ_Rows, y

			tay
			lda #<SpriteIRQ
			ldx #>SpriteIRQ
			jsr SetNextInterrupt 

		NoSprites:

		asl VIC.INTERRUPT_STATUS

		SetDebugBorder(0)

		:RestoreState()

		rti

	}

	





}