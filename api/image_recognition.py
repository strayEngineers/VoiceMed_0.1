from dotenv import load_dotenv
import os
from google.cloud import vision
import cv2
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime

def crop_image(image_fie):
    # 使用 NumPy 將圖片內容轉換為 OpenCV 可讀的格式
    np_img = np.frombuffer(image_fie, np.uint8)
    img = cv2.imdecode(np_img, cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    blurred = cv2.GaussianBlur(gray, (5,5), 0)

    edges = cv2.Canny(blurred, 30, 150)
    final_kernel = np.ones((3,3), np.uint8)
    edges=cv2.dilate(edges,final_kernel,iterations=1)

    # 使用輪廓檢測
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # 找到最大的輪廓
    largest_contour = max(contours, key=cv2.contourArea)
    # 根據輪廓取得邊界框
    x, y, w, h = cv2.boundingRect(largest_contour)

    cropped_img = img[y:y+h, x:x+w]
    return cropped_img

def recognize_text(image_file):
    load_dotenv('env-config/.env')
    credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    client = vision.ImageAnnotatorClient.from_service_account_json(credentials_path)
    
    #image_file = cv2.imdecode(np.frombuffer(image_file, np.uint8), cv2.IMREAD_COLOR) 
    height, width, channel = image_file.shape
    image_file = image_file[0:height-int(height * 0.11), 0:width]
    is_success, buffer = cv2.imencode(".jpg", image_file)
    # 建立圖片物件
    image = vision.Image(content=buffer.tobytes())

    # 使用 Vision API 的文字辨識
    response = client.text_detection(image=image)

    # 取得文字辨識結果
    texts = response.text_annotations
    text = texts[0].description

    # 檢查是否有錯誤
    if response.error.message:
        raise Exception(f'{response.error.message}')
    print(text)
    return text


def plot(image,cmap=None):
    plt.figure(figsize=(15,15))
    plt.imshow(image,cmap=cmap) 
    plt.show()

def detect_box(image):
    gray_scale=cv2.cvtColor(image,cv2.COLOR_BGR2GRAY)
    th1,img_bin = cv2.threshold(gray_scale,127,225,cv2.THRESH_BINARY)

    # 針對每個像素做not的概念，前後景相反(白底黑字 --> 黑底白字)
    img_bin = ~img_bin

    # define the min of the box width(height)
    line_min_width = 20

    # define the kernals of morphologyEx function (horizontal, vertical)
    kernal_h = np.ones((1,line_min_width), np.uint8)
    kernal_v = np.ones((line_min_width,1), np.uint8)

    # find horizontal lines
    img_bin_h = cv2.morphologyEx(img_bin, cv2.MORPH_OPEN, kernal_h)

    # find vertical lines
    img_bin_v = cv2.morphologyEx(img_bin, cv2.MORPH_OPEN, kernal_v)

    # merge horizontal and vertical lines
    img_bin_final = img_bin_h | img_bin_v

    # closing small gaps of merge lines 
    final_kernel = np.ones((3,3), np.uint8)
    img_bin_final=cv2.dilate(img_bin_final,final_kernel,iterations=1)

    # get the box data
    ret, labels, stats,centroids = cv2.connectedComponentsWithStats(~img_bin_final, connectivity=8, ltype=cv2.CV_32S)
    return stats,labels,img_bin


def recognize_check_box(image_file):
    # 將 image_file (FileStorage物件)轉換為 NumPy 陣列
    #image_np = np.frombuffer(image_file, np.uint8)
    #image_file = cv2.imdecode(image_np, cv2.IMREAD_COLOR)

    image_file = cv2.resize(image_file, (1248, 1360), interpolation=cv2.INTER_LANCZOS4)
    height, width, channel = image_file.shape
    image_file = image_file[height-int(height * 0.11):height, 0:width]
    """ image_file = crop_image(image_file) """
    stats, labels, img_bin = detect_box(image_file)

    min_aspect_ratio = 0.8
    max_aspect_ratio = 1.2
    min_area = 1000
    max_area = 1800
    check_box = [False, False, False, False, False, False]

    # stats[0]為背景、stats[1]為整體的資料
    for x,y,w,h,area in stats[2: ]:
        aspect_ratio = w / h
        if ((min_area <= area <= max_area) and (min_aspect_ratio <= aspect_ratio <= max_aspect_ratio) and y<10):
            # 這邊的img_bin為黑底白字
            checkbox = img_bin[y:y+h, x:x+w]
            # 找出白色(為1)的 pixel 數量
            non_zero_pixels = cv2.countNonZero(~checkbox)
            pixel_density = non_zero_pixels / (w * h)

            # 若白色的密度低於 95% 表示有被打勾
            if pixel_density < 0.95:
                index = round(x/200)
                check_box[index] = True

    reminder = {
        "早餐Breakfast" : False,
        "午餐Lunch" : False,
        "晚餐Dinner" : False,
        "睡前Bedtime" : False
    }
    reminder_time = {
        "早餐Breakfast" : "07:00:00.000000",
        "午餐Lunch" : "12:00:00.000000",
        "晚餐Dinner" : "18:00:00.000000",
        "睡前Bedtime" : "22:00:00.000000"
    }
    # 將有打勾的時段設為 True 
    index = 0
    for key, value in reminder.items():
        if check_box[index]:
            reminder.update({key:True})
        index += 1

    # 準備要放入資料庫的 data
    output = []
    for key, value in reminder.items():
        if value:
            # datetime = yyyy-mm-dd hh:mm:ss.ssssss
            alarm_datetime = datetime.now().strftime("%Y-%m-%d") + " " + reminder_time[key]
            output.append({"title":key, "alarmDateTime":alarm_datetime, "isRepeating":True, "isEnabled":True, "gradientColorIndex":0})
    print(output)
    return output
