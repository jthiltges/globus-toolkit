/*
 * Copyright 1999-2006 University of Chicago
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.globus.usage.packets;

import java.io.Serializable;

/*
 * This replaces the java.nio.ByteBuffer class which is not in Java 
 * platform 1.3.
 */
public class CustomByteBuffer implements Serializable {

    private int maxSize;
    private int bytesUsed;
    private int pointer;
    private byte[] internalArray;

    /* older versions of the senders used little endian packet formats */
    private static final short ENDIAN_CHECK_HACK = 24;
    boolean little_endian_packet;

    private final static int LONG_SIZE = 8;
    private final static int INT_SIZE = 4;
    private final static int SHORT_SIZE = 2;

    public CustomByteBuffer(int maxSize) {
        this.internalArray = new byte[maxSize];
        this.maxSize = maxSize;
        this.pointer = bytesUsed = 0;
        this.little_endian_packet = false;
    }

    private CustomByteBuffer() {
        this.little_endian_packet = false;
    }

    public static CustomByteBuffer fitToData(byte[] existingArray, int size) {
	/*Makes a new array of just size bytes, and copies the first size
	  bytes of the existing array into it.*/
	CustomByteBuffer newBuf = new CustomByteBuffer(size);
	System.arraycopy(existingArray, 0, newBuf.internalArray, 0, size);
	newBuf.bytesUsed = size;

	if (newBuf.bytesUsed > (2 * SHORT_SIZE) && 
           (newBuf.getShort() > ENDIAN_CHECK_HACK ||
            newBuf.getShort() > ENDIAN_CHECK_HACK)) {

            newBuf.setLittleEndian();
	}
        newBuf.rewind();
	return newBuf;
    }

    public static CustomByteBuffer wrap(byte[] existingArray) {
        CustomByteBuffer newByteBuffer = new CustomByteBuffer();
        newByteBuffer.internalArray = existingArray;
        newByteBuffer.maxSize = newByteBuffer.bytesUsed = existingArray.length;
	newByteBuffer.pointer = 0;

	if (newByteBuffer.bytesUsed > (2 * SHORT_SIZE) && 
           (newByteBuffer.getShort() > ENDIAN_CHECK_HACK ||
            newByteBuffer.getShort() > ENDIAN_CHECK_HACK)) {

            newByteBuffer.setLittleEndian();
	}
        newByteBuffer.rewind();

        return newByteBuffer;
    }

    public void shrink() {
        /*Shrink to minimum occupied size... be careful with this*/
        byte[] smallerArray = new byte[bytesUsed];
        System.arraycopy(this.internalArray, 0, smallerArray, 0, bytesUsed);
        this.internalArray = smallerArray;
        this.maxSize = internalArray.length;
    }

    public int limit() {
        return this.maxSize;
    }
    
    public int position() {
        return this.pointer;
    }
    
    public int remaining() {
        return this.maxSize - this.pointer;
    }

    public byte[] array() {
        shrink();
        return this.internalArray;
    }

    public void rewind() {
        this.pointer = 0;
    }
    
    public byte get() {
        byte nextByte = this.internalArray[this.pointer];
        this.pointer++;
        return nextByte;
    }
    
    public void get(byte[] dataGoesHere) {
        get(dataGoesHere, 0, dataGoesHere.length);
    }

    public void setLittleEndian() {
        this.little_endian_packet = true;
    }
    
    public void get(byte[] dataGoesHere, int offset, int numBytes) {
	System.arraycopy(this.internalArray, this.pointer, 
			 dataGoesHere, offset, 
			 numBytes);
	this.pointer += numBytes;
	
    }

    public void getBytes(byte[] dataGoesHere) {
	get(dataGoesHere, 0, dataGoesHere.length);
    }

    public byte[] getRemainingBytes() {
	int remaining = this.remaining();
	byte[] remainingBytes = new byte[remaining];
	get(remainingBytes, 0, remaining);
	return remainingBytes;
    }

    public String getUntilZeroOrOne(int maxBytes) {
        /*copy into the destination array until we run out of  bytes,
          or the array is filled up, or until we see a byte that is
        zero or one. (Needed by GramUsageMonitorPacket).*/

        StringBuffer buf = new StringBuffer();

        for (int i = 0; i<maxBytes; i++) {
            char c = (char)this.internalArray[this.pointer];
            if (c > 1) {
                buf.append(c);
                this.pointer++;
            }
            else {
                break;
            }
        }

        return buf.toString();
    }

    public long getLong() {
        long out = 0;

        if (little_endian_packet)
        {
            for (int i=LONG_SIZE-1; i>=0; i--) {
                out = out << 8;
                out |= (this.internalArray[this.pointer+i] & 0xFF);
            }
            this.pointer += LONG_SIZE;
        }
        else
        {
            out  = (((long) internalArray[pointer++]) << 56) &
                    0xff00000000000000L;
            out |= (((long) internalArray[pointer++]) << 48) &
                    0x00ff000000000000L;
            out |= (((long) internalArray[pointer++]) << 40) &
                    0x0000ff0000000000L;
            out |= (((long) internalArray[pointer++]) << 32) &
                    0x000000ff00000000L;
            out |= (((long) internalArray[pointer++]) << 24) &
                    0x00000000ff000000L;
            out |= (((long) internalArray[pointer++]) << 16) &
                    0x0000000000ff0000L;
            out |= (((long) internalArray[pointer++]) <<  8) &
                    0x000000000000ff00L;
            out |= (((long) internalArray[pointer++])) &
                    0x00000000000000ffL;
        }
        return out;
    }

    public int getInt() {
        int out = 0;

        if (little_endian_packet)
        {
            for (int i=INT_SIZE-1; i>=0; i--) {
                out = out << 8;
                out |= (this.internalArray[this.pointer+i] & 0xFF);
            }
            this.pointer += INT_SIZE;
        }
        else
        {
            out  = (((int) internalArray[pointer++]) << 24) & 0xff000000;
            out |= (((int) internalArray[pointer++]) << 16) & 0x00ff0000;
            out |= (((int) internalArray[pointer++]) <<  8) & 0x0000ff00;
            out |= (((int) internalArray[pointer++])      ) & 0x000000ff;
        }
        return out;
    }

    public int getIntBigEndian() {
	int out = 0;

        if (little_endian_packet)
        {
            for (int i=0; i<INT_SIZE; i++) {
                out = out << 8;
                out |= (this.internalArray[this.pointer+i] & 0xFF);
            }
            this.pointer += INT_SIZE;
        }
        else
        {
            out = getInt();
        }
	return out;
    }

    public short getShort() {
        short out = 0;

        if (little_endian_packet)
        {
            for (int i=SHORT_SIZE-1; i>=0; i--) {
                out = (short)(out << 8);
                out |= (this.internalArray[this.pointer+i] & 0xFF);
            }
            this.pointer += SHORT_SIZE;
        }
        else
        {
            out |= (((short) internalArray[pointer++]) <<  8) & 0xff00;
            out |= (((short) internalArray[pointer++])) & 0x00ff;
        }
        return out;
    }

    public void put(byte datum) {
        this.internalArray[this.pointer] = datum;
        this.pointer++;
        if (this.pointer > this.bytesUsed) {
            this.bytesUsed = this.pointer;
        }
    }

    public void put(byte[] data) {
        put(data, 0, data.length);
    }

    public void put(byte[] data, int offset, int numBytes) {
        System.arraycopy(data, offset, 
                         this.internalArray, this.pointer, 
                         numBytes);
        this.pointer += numBytes;
        if (this.pointer > this.bytesUsed) {
            this.bytesUsed = this.pointer;
        }
    }
    
    public void putLong(long datum) {
        if (little_endian_packet)
        {
            for (int i=0; i<LONG_SIZE; i++) {
                this.internalArray[this.pointer + i] = (byte)datum;
                datum = datum >> 8;
            }
            this.pointer += LONG_SIZE;
        }
        else
        {
            internalArray[pointer++] = (byte)((datum&0xff00000000000000L)>>>56);
            internalArray[pointer++] = (byte)((datum&0x00ff000000000000L)>>>48);
            internalArray[pointer++] = (byte)((datum&0x0000ff0000000000L)>>>40);
            internalArray[pointer++] = (byte)((datum&0x000000ff00000000L)>>>32);
            internalArray[pointer++] = (byte)((datum&0x00000000ff000000L)>>>24);
            internalArray[pointer++] = (byte)((datum&0x0000000000ff0000L)>>>16);
            internalArray[pointer++] = (byte)((datum&0x000000000000ff00L)>>>8);
            internalArray[pointer++] = (byte)((datum&0x00000000000000ffL));
        }
        if (this.pointer > this.bytesUsed) {
            this.bytesUsed = pointer;
        }
    }

    public void putInt(int datum) {
        if (little_endian_packet)
        {
            for (int i=0; i<INT_SIZE; i++) {
                this.internalArray[this.pointer + i] = (byte)datum;
                datum = datum >> 8;
            }
            this.pointer += INT_SIZE;
        }
        else
        {
            internalArray[pointer++] = (byte)((datum&0xff000000)>>>24);
            internalArray[pointer++] = (byte)((datum&0x00ff0000)>>>16);
            internalArray[pointer++] = (byte)((datum&0x0000ff00)>>> 8);
            internalArray[pointer++] = (byte)((datum&0x000000ff));
        }
        if (this.pointer > this.bytesUsed) {
            this.bytesUsed = pointer;
        }
    }

    public void putShort(short datum) {
        if (little_endian_packet)
        {
            for (int i=0; i<SHORT_SIZE; i++) {
                this.internalArray[this.pointer + i] = (byte)datum;
                datum = (short)(datum >> 8);
            }
            this.pointer += SHORT_SIZE;
        }
        else
        {
            internalArray[pointer++] = (byte)((datum&0xff00)>>>8);
            internalArray[pointer++] = (byte)((datum&0x00ff));
        }
        if (this.pointer > this.bytesUsed) {
            this.bytesUsed = pointer;
        }
    }
}